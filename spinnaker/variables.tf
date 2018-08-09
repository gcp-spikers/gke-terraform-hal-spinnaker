variable "project" {
  description = "Project id"
}

variable "gcs_location" {
  description = "GCS bucket location"
}

variable "gcs_class_storage" {
  description = "Storage Class for spinnaker config bucket"
}

variable "spinnaker_sa" {
  default     = "spinnaker"
  description = "GCP service account for Spinnnaker. Default to 'spinnaker'"
}