output "gcs_bucket_name" {
  description = "GCS bucket for raw data"
  value       = google_storage_bucket.retailpulse_data.name
}

output "service_account_email" {
  description = "RetailPulse service account email"
  value       = google_service_account.retailpulse.email
}

output "bigquery_datasets" {
  description = "Created BigQuery dataset IDs"
  value       = [for ds in google_bigquery_dataset.datasets : ds.dataset_id]
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}
