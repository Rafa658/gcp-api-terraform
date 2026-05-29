output "secret_id" {
  value       = google_secret_manager_secret.db_pass_secret.id
  description = "O ID do segredo criado no Secret Manager para a senha do banco"
}

output "db_password" {
  value       = random_password.db_password.result
  description = "A senha gerada para o banco de dados, armazenada no Secret Manager"
}