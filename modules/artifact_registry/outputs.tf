output "artifact_registry_repo_url" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.api_repo.repository_id}"
  description = "A URL do repositorio no Artifact Registry para fazer o push da imagem Docker"
}