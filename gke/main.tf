provider "google" {
  version = "~> 1.16"
  project = "${var.project}"
  zone    = "${var.zone}"
}

# Enable API's for the project
resource "google_project_services" "myproject" {
  disable_on_destroy = false

  services = [
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "pubsub.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "container.googleapis.com",
    "oslogin.googleapis.com",
    "containerregistry.googleapis.com",
    "compute.googleapis.com",
    "deploymentmanager.googleapis.com",
    "replicapool.googleapis.com",
    "replicapoolupdater.googleapis.com",
    "resourceviews.googleapis.com",
    "cloudbuild.googleapis.com",
    "sourcerepo.googleapis.com",
    "bigquery-json.googleapis.com",
  ]
}

# Create GKE cluster for EA Base Infrastructure
module "gke_cluster" {
  source             = "modules/cluster"
  name               = "${var.cluster_name}"
  initial_node_count = "${var.cluster_nodes_count}"
  machine_type       = "${var.node_type}"
  zone               = "${var.zone}"
  tags               = ["dev"]

  ## Generated Project id is used here to create dependency between project services resource and cluster creation
  project = "${google_project_services.myproject.id}"
}