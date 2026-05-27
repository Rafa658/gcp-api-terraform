output "db_private_ip" {
  value       = google_sql_database_instance.db_instance.private_ip_address
  description = "IP interno do banco de dados"
}

output "db_user" {
  value       = google_sql_user.db_user.name
  description = "Nome do usuário do banco de dados"
}

output "db_name" {
  value       = google_sql_database.database.name
  description = "Nome do schema lógico do banco"
}

output "db_connection_name" {
  value       = google_sql_database_instance.db_instance.connection_name
  description = "O connection name gerado para a instância do Cloud SQL"
}