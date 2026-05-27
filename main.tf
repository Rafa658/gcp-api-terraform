# Configurações globais do Terraform
terraform {
  required_version = ">= 1.5.0"

# Adicione este bloco configurando o backend remoto
  backend "gcs" {
    bucket = "gcp-api-tfstate-bucket" # O nome exato do bucket que você criou no Passo 1
    prefix = "terraform/state"            # Caminho (pasta) dentro do bucket onde o state ficará
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Garante compatibilidade sem quebrar o código com updates major
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Configuração do Provedor GCP
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

module "network" {
  source      = "./modules/network" # Caminho relativo para a pasta do módulo
  project_id  = var.project_id
  environment = var.environment
  region      = var.region
}

# CHAMADA DO NOVO MÓDULO DE COMPUTAÇÃO
module "cloud_run_api" {
  source           = "./modules/cloud_run" # Caminho para a nova pasta
  project_id       = var.project_id
  environment      = var.environment
  region           = var.region
  vpc_connector_id = module.network.connector_id
  db_host          = google_sql_database_instance.db_instance.private_ip_address
  db_user          = google_sql_user.db_user.name
  db_name          = google_sql_database.database.name
  secret_id        = google_secret_manager_secret.db_pass_secret.secret_id
}

resource "google_project_service" "sqladmin_api" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking_api" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.network.network_id # Lendo o ID vindo de dentro do módulo
  depends_on    = [google_project_service.servicenetworking_api]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.network.network_id # Lendo o ID vindo do módulo
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

resource "google_sql_database_instance" "db_instance" {
  name                = "db-${var.environment}"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = module.network.network_id # Lendo o ID vindo do módulo
      enable_private_path_for_google_cloud_services = true
    }
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.sqladmin_api
  ]
}

# 4. Cria o Banco de Dados lógico dentro da instância
resource "google_sql_database" "database" {
  name     = "api_db"
  instance = google_sql_database_instance.db_instance.name
}

# 5. Cria o Usuário do Banco de Dados
resource "google_sql_user" "db_user" {
  name     = "api_user"
  instance = google_sql_database_instance.db_instance.name
  password = random_password.db_password.result # String temporária
}

# Ativa a API do Secret Manager
resource "google_project_service" "secretmanager_api" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Gera uma senha randômica forte de 16 caracteres
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Cria o "container" do segredo no Secret Manager
resource "google_secret_manager_secret" "db_pass_secret" {
  secret_id = "db-password-${var.environment}"
  
  replication {
    auto {} # Replica o segredo automaticamente de forma global/regionalizada pela GCP
  }

  depends_on = [google_project_service.secretmanager_api]
}

# Insere a senha gerada como a Versão 1 desse segredo
resource "google_secret_manager_secret_version" "db_pass_version" {
  secret      = google_secret_manager_secret.db_pass_secret.id
  secret_data = random_password.db_password.result
}

# Ativa a API do Artifact Registry
resource "google_project_service" "artifactregistry_api" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Cria o repositório do Artifact Registry para armazenar as imagens Docker da API
resource "google_artifact_registry_repository" "api_repo" {
  location      = var.region
  repository_id = "repo-${var.environment}"
  description   = "Repositorio Docker privado para a API de producao"
  format        = "DOCKER"

  depends_on = [google_project_service.artifactregistry_api]
}

# Ativa a API do Cloud Run
resource "google_project_service" "run_api" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}