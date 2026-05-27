resource "google_project_service" "run_api" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# 1. Service Account dedicada para a aplicação
resource "google_service_account" "run_sa" {
  account_id   = "cr-api-sa-${var.environment}"
  display_name = "Service Account para a API no Cloud Run"
}

# 2. Vínculo de permissão para ler o segredo do banco
resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = var.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run_sa.email}"
}

# 3. O Serviço do Cloud Run
resource "google_cloud_run_v2_service" "api_service" {
  name     = "api-service-${var.environment}"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.run_sa.email

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "ALL_TRAFFIC"
    }

    containers {
      image = "gcr.io/cloudrun/hello"

      env {
        name  = "DB_HOST"
        value = var.db_host
      }
      env {
        name  = "DB_USER"
        value = var.db_user
      }
      env {
        name  = "DB_NAME"
        value = var.db_name
      }
      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = var.secret_id
            version = "latest"
          }
        }
      }
    }
  }

  depends_on = [
    google_project_service.run_api,
    google_secret_manager_secret_iam_member.secret_access
  ]
}

# 4. Torna o endpoint público
resource "google_cloud_run_v2_service_iam_member" "allow_public" {
  name     = google_cloud_run_v2_service.api_service.name
  location = google_cloud_run_v2_service.api_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}