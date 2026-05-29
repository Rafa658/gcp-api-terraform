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
  source           = "./modules/cloud_run"
  project_id       = var.project_id
  environment      = var.environment
  region           = var.region
  vpc_connector_id = module.network.connector_id
  
  # Capturando dados dinamicamente a partir dos outputs do módulo DB:
  db_host          = module.db.db_private_ip
  db_user          = module.db.db_user
  db_name          = module.db.db_name
  
  secret_id        = google_secret_manager_secret.db_pass_secret.secret_id
}

module "db" {
  source      = "./modules/db"
  project_id  = var.project_id
  environment = var.environment
  region      = var.region
  network_id  = module.network.network_id
  db_password = random_password.db_password.result # Passando a senha gerada na raiz
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