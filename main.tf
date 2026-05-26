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
  }
}

# Configuração do Provedor GCP
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Nota: Os recursos da nossa API (VPC, SQL, Cloud Run) entrarão aqui nos próximos capítulos.
