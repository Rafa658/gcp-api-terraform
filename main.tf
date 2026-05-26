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
