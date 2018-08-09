provider "google" {
  version = "~> 1.16"
  project = "${var.project}"
}

# Create GCS bucket
resource "google_storage_bucket" "spinnaker_config" {
  name          = "${var.project}-spinnaker-config"
  location      = "${var.gcs_location}"
  storage_class = "${var.gcs_class_storage}"
  force_destroy = "false"
}

# Create service account for spinnaker
resource "google_service_account" "spinnaker" {
  depends_on = [
    "google_storage_bucket.spinnaker_config",
  ]

  account_id   = "${var.spinnaker_sa}"
  display_name = "${var.spinnaker_sa}"
}

# Grant storage admin to spinnaker service account
resource "google_project_iam_binding" "spinnaker" {
  role = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.spinnaker.email}",
  ]
}

# Generate key for spinnaker GCS service account
resource "google_service_account_key" "spinnaker" {
  service_account_id = "${google_service_account.spinnaker.name}"
}