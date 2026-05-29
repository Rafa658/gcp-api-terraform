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