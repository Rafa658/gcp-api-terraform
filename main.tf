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

# Nota: Os recursos da nossa API (VPC, SQL, Cloud Run) entrarão aqui nos próximos capítulos.

# Ativa a API de Computação (necessária para redes)
resource "google_project_service" "compute_api" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# Ativa a API do VPC Access (necessária para o conector Serverless)
resource "google_project_service" "vpcaccess_api" {
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

# Cria a VPC Customizada
resource "google_compute_network" "vpc" {
  name                    = "vpc-${var.environment}"
  auto_create_subnetworks = false # Evita a criação de subredes automáticas e pesadas
  depends_on              = [google_project_service.compute_api]
}

# Cria uma subrede padrão para uso geral
resource "google_compute_subnetwork" "subnet" {
  name          = "sb-${var.environment}-${var.region}"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Cria o Serverless VPC Access Connector
resource "google_vpc_access_connector" "connector" {
  name          = "vpc-cx-${var.environment}"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.8.0.0/28" # Bloco /28 reservado exclusivamente para o conector

  # Garante que as APIs e a rede já existam antes de tentar criar o conector
  depends_on = [
    google_project_service.vpcaccess_api,
    google_compute_network.vpc
  ]
}

# Ativa a API do Cloud SQL Admin
resource "google_project_service" "sqladmin_api" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Ativa a API de Service Networking (necessária para o VPC Peering do banco)
resource "google_project_service" "servicenetworking_api" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

# 1. Reserva um bloco de IP interno dentro da nossa VPC para o Cloud SQL
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16 # Reserva um bloco /16 para os serviços internos da GCP
  network       = google_compute_network.vpc.id
  depends_on    = [google_project_service.servicenetworking_api]
}

# 2. Cria a conexão de Peering entre a nossa VPC e os serviços internos do Google
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

# 3. Cria a Instância do Cloud SQL (PostgreSQL)
resource "google_sql_database_instance" "db_instance" {
  name             = "db-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-f1-micro" # Instância mais barata, ideal para desenvolvimento/laboratório

    ip_configuration {
      ipv4_enabled                                  = false # DESLIGA o IP público permanentemente
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_google_cloud_services = true
    }
  }

  # Garante que a rede e o peering estejam prontos antes de tentar criar o banco
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