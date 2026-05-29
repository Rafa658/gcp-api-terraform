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