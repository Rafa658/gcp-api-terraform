output "project_id" {
  value       = var.project_id
  description = "Confirmação do ID do projeto GCP utilizado"
}

output "environment" {
  value       = var.environment
  description = "O ambiente atual onde o deploy foi executado"
}

output "network_name" {
  value       = module.network.network_name
  description = "O nome da VPC criada e gerenciada pelo modulo local"
}

output "vpc_connector_name" {
  value       = module.network.connector_name
  description = "O nome do Serverless VPC Access Connector"
}

output "db_instance_connection_name" {
  value       = google_sql_database_instance.db_instance.connection_name
  description = "O connection name do Cloud SQL (usado pelo Cloud Run)"
}

output "db_private_ip" {
  value       = google_sql_database_instance.db_instance.private_ip_address
  description = "O endereço IP privado alocado para o banco de dados"
}

output "secret_id" {
  value       = google_secret_manager_secret.db_pass_secret.id
  description = "O ID do segredo criado no Secret Manager para a senha do banco"
}

output "artifact_registry_repo_url" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.api_repo.repository_id}"
  description = "A URL do repositorio no Artifact Registry para fazer o push da imagem Docker"
}

output "api_url" {
  value       = google_cloud_run_v2_service.api_service.uri
  description = "A URL publica gerada para acessar a API em producao"
}