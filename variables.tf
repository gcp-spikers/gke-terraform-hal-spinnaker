variable "project" {
  description = "The ID of the project to apply any resources to."
}

variable "zone" {
  default = "asia-southeast1-b"
}

variable "gcs_location" {
  default = "Asia"
}

variable "cluster_name" {
  default     = "spinnaker"
  description = "GKE cluster name"
}

variable "cluster_nodes_count" {
  default     = 2
  description = "Number of nodes in the GKE cluster"
}

variable "node_type" {
  default     = "n1-standard-2"
  description = "VM Node type"
}
