resource "google_project_service" "sqladmin_api" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking_api" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

# 1. Reserva de IP privado dentro da VPC repassada
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network_id
  depends_on    = [google_project_service.servicenetworking_api]
}

# 2. Conexão de Peering com o Google Services
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

# 3. Instância do Cloud SQL (PostgreSQL)
resource "google_sql_database_instance" "db_instance" {
  name                = "db-${var.environment}"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = false # Mantido false para facilitar laboratórios

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_id
      enable_private_path_for_google_cloud_services = true
    }
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.sqladmin_api
  ]
}

# 4. Banco lógico
resource "google_sql_database" "database" {
  name     = "api_db"
  instance = google_sql_database_instance.db_instance.name
}

# 5. Usuário do Banco consumindo a senha randômica do orquestrador
resource "google_sql_user" "db_user" {
  name     = "api_user"
  instance = google_sql_database_instance.db_instance.name
  password = var.db_password
}