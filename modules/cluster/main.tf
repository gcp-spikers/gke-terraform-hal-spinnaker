data "google_container_engine_versions" "gke_versions" {
  zone = "${var.zone}"
}

resource "google_container_cluster" "primary" {
  name               = "${var.name}"
  min_master_version = "${data.google_container_engine_versions.gke_versions.latest_master_version}"
  project            = "${var.project}"
  node_version       = "${data.google_container_engine_versions.gke_versions.latest_node_version}"

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

      #oauth_scopes = "${var.oauth_scopes}"
    }
  }
}

data "template_file" "gcloud_config" {
  template = <<EOF
set -ex \
&& gcloud container clusters --zone=$${zone} --project=$${project} get-credentials $${cluster_name} \
&& kubectl version
EOF

  vars {
    project      = "${var.project}"
    zone         = "${var.zone}"
    cluster_name = "${google_container_cluster.primary.id}"
  }
}

resource "null_resource" "gcloud_config" {
  provisioner "local-exec" {
    command = "${data.template_file.gcloud_config.rendered}"
  }
}
