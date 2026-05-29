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
  
  secret_id        = module.secret_manager.secret_id # Passando o ID do segredo para o Cloud Run acessar a senha do DB
}

module "db" {
  source      = "./modules/db"
  project_id  = var.project_id
  environment = var.environment
  region      = var.region
  network_id  = module.network.network_id
  db_password = module.secret_manager.db_password # Passando a senha gerada no módulo de secret manager
}

module "artifact_registry" {
  source      = "./modules/artifact_registry"
  project_id  = var.project_id
  environment = var.environment
  region      = var.region

  repo_url    = module.artifact_registry.artifact_registry_repo_url
}

module "secret_manager" {
  source      = "./modules/secret_manager"

  project_id  = var.project_id
  environment = var.environment
}