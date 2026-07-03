variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "GCS bucket name for raw data"
  type        = string
}

variable "dataset_prefix" {
  description = "Prefix for BigQuery dataset names"
  type        = string
  default     = "retailpulse"
}

variable "service_account_id" {
  description = "Service account ID for RetailPulse"
  type        = string
  default     = "retailpulse-sa"
}

variable "create_composer_env" {
  description = "Whether to create a Composer environment (expensive)"
  type        = bool
  default     = false
}
