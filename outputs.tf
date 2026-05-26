output "project_id" {
  value       = var.project_id
  description = "Confirmação do ID do projeto GCP utilizado"
}

output "environment" {
  value       = var.environment
  description = "O ambiente atual onde o deploy foi executado"
}

output "network_name" {
  value       = google_compute_network.vpc.name
  description = "O nome da VPC criada"
}

output "vpc_connector_name" {
  value       = google_vpc_access_connector.connector.name
  description = "O nome do Serverless VPC Access Connector"
}
