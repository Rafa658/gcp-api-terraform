output "api_url" {
  value       = google_cloud_run_v2_service.api_service.uri
  description = "A URL pública exposta pelo módulo do Cloud Run"
}