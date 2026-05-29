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
  value       = module.db.db_connection_name
  description = "O connection name do Cloud SQL (usado pelo Cloud Run)"
}

output "db_private_ip" {
  value       = module.db.db_private_ip
  description = "O endereço IP privado alocado para o banco de dados"
}

output "secret_id" {
  value       = module.secret_manager.secret_id
  description = "O ID do segredo criado no Secret Manager para a senha do banco"
}

output "artifact_registry_repo_url" {
  value       = module.artifact_registry.artifact_registry_repo_url
  description = "A URL do repositorio no Artifact Registry para fazer o push da imagem Docker"
}

output "api_url" {
  value       = module.cloud_run_api.api_url
  description = "A URL publica gerada para acessar a API em producao"
}