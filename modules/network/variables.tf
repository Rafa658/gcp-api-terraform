variable "project_id" {
  type        = string
  description = "ID do projeto GCP repassado pela raiz"
}

variable "environment" {
  type        = string
  description = "Ambiente (prod, dev, etc)"
}

variable "region" {
  type        = string
  description = "Região onde a rede e o conector serão criados"
}