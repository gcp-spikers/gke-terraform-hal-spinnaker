data "google_container_engine_versions" "gke_versions" {
  zone = "${var.zone}"
}

resource "google_container_cluster" "primary" {
  name               = "${var.name}"
  min_master_version = "${data.google_container_engine_versions.gke_versions.latest_master_version}"
  project            = "${var.project}"
  node_version       = "${data.google_container_engine_versions.gke_versions.latest_node_version}"

  /*
   * Disable default GKE logging and monitoring service, instead of this we will be using
   * Kubernetes Stackdriver Monitoring
   * Ref https://cloud.google.com/monitoring/kubernetes-engine/customizing for more info
   */

  logging_service    = "none"
  monitoring_service = "none"
  node_pool {
    name               = "${var.node_pool_name}"
    initial_node_count = "${var.initial_node_count}"

    autoscaling {
      min_node_count = "${var.min_node_count}"
      max_node_count = "${var.max_node_count}"
    }

    node_config {
      preemptible  = "${var.preemptible}"
      machine_type = "${var.machine_type}"
      disk_size_gb = "${var.disk_size_gb}"
      tags         = ["${var.tags}"]
      oauth_scopes = ["${var.oauth_scopes}"]
    }
  }
}

data "template_file" "stackdriver_k8s_monitor_install" {
  template = <<EOF
set -ex \
&& gcloud container clusters --zone=${var.zone} --project=${var.project} get-credentials ${google_container_cluster.primary.id} \
&& kubectl apply -f https://storage.googleapis.com/stackdriver-kubernetes/stable/rbac-setup.yaml --as=admin --as-group=system:masters \
&& kubectl apply -f https://storage.googleapis.com/stackdriver-kubernetes/stable/agents.yaml
EOF
}

resource "null_resource" "stackdriver_k8s_monitor_install" {
  triggers {
    cksum = "${sha256(data.template_file.stackdriver_k8s_monitor_install.template)}"
  }

  provisioner "local-exec" {
    command = "${data.template_file.stackdriver_k8s_monitor_install.rendered}"
  }
}
