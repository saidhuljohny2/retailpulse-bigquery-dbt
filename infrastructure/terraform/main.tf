# GCS bucket for raw data
resource "google_storage_bucket" "retailpulse_data" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = var.environment != "prod"

  uniform_bucket_level_access = true

  versioning {
    enabled = var.environment == "prod"
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  labels = {
    project     = "retailpulse"
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Service account for RetailPulse pipeline
resource "google_service_account" "retailpulse" {
  account_id   = "${var.service_account_id}-${var.environment}"
  display_name = "RetailPulse Service Account (${var.environment})"
  description  = "Service account for RetailPulse data pipeline"
}

# IAM: BigQuery Data Editor
resource "google_project_iam_member" "bq_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.retailpulse.email}"
}

# IAM: BigQuery Job User
resource "google_project_iam_member" "bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.retailpulse.email}"
}

# IAM: Storage Object Admin on bucket
resource "google_storage_bucket_iam_member" "gcs_admin" {
  bucket = google_storage_bucket.retailpulse_data.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.retailpulse.email}"
}

# BigQuery datasets
locals {
  dataset_suffixes = ["raw", "staging", "intermediate", "analytics", "reporting", "snapshots"]
}

resource "google_bigquery_dataset" "datasets" {
  for_each = toset(local.dataset_suffixes)

  dataset_id  = "${var.dataset_prefix}_${each.value}"
  location    = var.region
  description = "RetailPulse ${each.value} dataset (${var.environment})"

  labels = {
    project     = "retailpulse"
    environment = var.environment
    layer       = each.value
  }
}

# Optional Composer environment variables (without creating Composer by default)
# Uncomment and configure if create_composer_env = true
# resource "google_composer_environment" "retailpulse" {
#   count   = var.create_composer_env ? 1 : 0
#   name    = "retailpulse-composer-${var.environment}"
#   region  = var.region
#
#   config {
#     software_config {
#       image_version = "composer-2-airflow-2.8.1-build.1"
#       env_variables = {
#         GCP_PROJECT_ID     = var.project_id
#         GCS_BUCKET_NAME    = var.bucket_name
#         DBT_DATASET_PREFIX = var.dataset_prefix
#         DBT_TARGET         = var.environment
#         AIRFLOW_ENV        = var.environment
#       }
#     }
#     node_config {
#       service_account = google_service_account.retailpulse.email
#     }
#   }
#
#   depends_on = [google_service_account.retailpulse]
# }
