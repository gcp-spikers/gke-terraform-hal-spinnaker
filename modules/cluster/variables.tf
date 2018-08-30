variable "name" {
  description = "The name of the cluster, unique within the project and zone."
}

variable "node_pool_name" {
  default     = "autoscale-np"
  description = "The name of the node pool"
}

variable "initial_node_count" {
  default     = 3
  description = "The number of nodes to create in this cluster (not including the Kubernetes master). Default to 3"
}

variable "min_node_count" {
  default     = 1
  description = "Minimum number of nodes in the NodePool. Must be >=1 and <= max_node_count Default to 1"
}

variable "max_node_count" {
  default     = 3
  description = "Maximum number of nodes in the NodePool. Must be >= min_node_count. Default to 3"
}

variable "disk_size_gb" {
  default = 50
}

variable "preemptible" {
  default     = true
  description = "A boolean that represents whether or not the underlying node VMs are preemptible. See the official documentation for more information. Defaults to true."
}

variable "machine_type" {
  default     = "n1-standard-1"
  description = "The name of a Google Compute Engine machine type. Defaults to n1-standard-4"
}

variable "min_master_version" {
  default     = "1.10.5-gke.3"
  description = "The minimum version of the master"
}

variable "tags" {
  type        = "list"
  default     = []
  description = "The list of instance tags applied to all nodes. Tags are used to identify valid sources or targets for network firewalls."
}

variable "oauth_scopes" {
  type = "list"

  default = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append",
  ]

  description = <<EOF
list of scopes for node pool, refer
  - https://cloud.google.com/sdk/gcloud/reference/container/node-pools/create
  - https://medium.com/google-cloud/updating-google-container-engine-vm-scopes-with-zero-downtime-50bff87e5f80
EOF
}

variable "project" {
  description = "The ID of the project to apply any resources to."
}

variable "zone" {
  default = "asia-southeast1-b"
}

# Refer https://medium.com/@bonya/terraform-adding-depends-on-to-your-custom-modules-453754a8043e
variable "depends_on" {
  default     = []
  type        = "list"
  description = "Hack for expressing module to module dependency"
}
