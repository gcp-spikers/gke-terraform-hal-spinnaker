terraform {
  backend "gcs" {
    bucket  = "terraform-remote-state-afd9626fd"
    prefix  = "spinnaker-dev"
  }
}

provider "google" {
  version = "~> 1.16"
  project = "${var.project}"
}

# k8s provider is used for installing helm
provider "kubernetes" {
  load_config_file = true
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

# Grant spinnaker service account OWNER of spinnaker config bucket
resource "google_storage_bucket_acl" "spinnaker-bucket-acl" {
  bucket = "${google_storage_bucket.spinnaker_config.name}"

  role_entity = [
    "OWNER:user-${google_service_account.spinnaker.email}"
  ]
}

# Generate key for spinnaker GCS service account
resource "google_service_account_key" "spinnaker" {
  service_account_id = "${google_service_account.spinnaker.name}"
}

