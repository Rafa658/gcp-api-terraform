output "network_id" {
  value       = google_compute_network.vpc.id
  description = "ID da VPC utilizável por outros recursos externos"
}

output "network_name" {
  value       = google_compute_network.vpc.name
  description = "Nome da VPC criada"
}

output "connector_id" {
  value       = google_vpc_access_connector.connector.id
  description = "ID do VPC Connector para acoplamento no Cloud Run"
}

output "connector_name" {
  value       = google_vpc_access_connector.connector.name
  description = "Nome do VPC Connector para acoplamento no Cloud Run"
}