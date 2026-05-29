variable "project_id" {
  type        = string
  default     = "gen-lang-client-0609880492" # Define o ID fixo do seu projeto GCP
  description = "O ID do projeto na GCP onde a infraestrutura será criada"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "A região padrão para os recursos que suportam regionalização"
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "A zona padrão para os recursos zonais (como instâncias de computação)"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Nome do ambiente (ex: dev, staging, prod)"
}
