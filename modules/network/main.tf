# Ativa as APIs necessárias para a rede existir
resource "google_project_service" "compute_api" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "vpcaccess_api" {
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

# Cria a VPC Customizada
resource "google_compute_network" "vpc" {
  name                    = "vpc-${var.environment}"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.compute_api]
}

# Cria a sub-rede
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
  ip_cidr_range = "10.8.0.0/28"

  depends_on = [
    google_project_service.vpcaccess_api,
    google_compute_network.vpc
  ]
}