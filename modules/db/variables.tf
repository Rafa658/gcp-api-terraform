variable "project_id" { type = string }
variable "environment" { type = string }
variable "region" { type = string }
variable "network_id" { type = string }
variable "db_password" { 
  type        = string
  sensitive   = true # Evita que a senha vaze nos logs do terminal do módulo
}