# Create spinnaker namespace
resource "kubernetes_namespace" "spinnaker" {
  "metadata" {
    name = "${var.spinnaker_k8s_namespace}"

    annotations {
      # To ensure namespace is created only after previous module completes
      depends-id = "${join(",", var.depends_on)}"
    }
  }
}

# Create kubernetes service account for spinnaker
resource "kubernetes_service_account" "spinnaker" {
  depends_on = [
    "kubernetes_namespace.spinnaker",
  ]

  "metadata" {
    name      = "${var.spinnaker_k8s_sa}"
    namespace = "${kubernetes_namespace.spinnaker.metadata.0.name}"
  }
}

# Create GCS bucket
resource "google_storage_bucket" "spinnaker_config" {
  name          = "${var.project}-spinnaker-config"
  location      = "${var.gcs_location}"
  storage_class = "NEARLINE"
  force_destroy = "true"
}

# Create service account for spinner storage on gcs
resource "google_service_account" "spinnaker_gcs" {
  account_id   = "${var.spinnaker_gcs_sa}"
  display_name = "${var.spinnaker_gcs_sa}"
}

# Create service account for GCR
resource "google_service_account" "spinnaker_gcr" {
  account_id   = "${var.spinnaker_gcr_sa}"
  display_name = "${var.spinnaker_gcr_sa}"
}

# Grant storage admin to spinnaker GCS service account (needs to be revised, ACL is more preferred)
resource "google_project_iam_binding" "role_storage_admin" {
  role = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.spinnaker_gcs.email}",
    "serviceAccount:${google_service_account.spinnaker_gcr.email}",
  ]
}

resource "google_project_iam_binding" "role_browser" {
  role = "roles/browser"

  members = [
    "serviceAccount:${google_service_account.spinnaker_gcr.email}",
  ]
}

resource "google_project_iam_binding" "role_compute_viewer" {
  role = "roles/compute.viewer"

  members = [
    "serviceAccount:${google_service_account.spinnaker_gcs.email}",
  ]
}

resource "google_project_iam_binding" "role_logging_admin" {
  role = "roles/logging.admin"

  members = [
    "serviceAccount:${google_service_account.spinnaker_gcs.email}",
  ]
}

resource "google_project_iam_binding" "role_monitoring_admin" {
  role = "roles/monitoring.admin"

  members = [
    "serviceAccount:${google_service_account.spinnaker_gcs.email}",
  ]
}

# Generate key for spinnaker GCS service account
resource "google_service_account_key" "spinnaker_gcs" {
  depends_on = [
    "google_project_iam_binding.role_storage_admin",
  ]

  service_account_id = "${google_service_account.spinnaker_gcs.name}"
}

# Generate key for spinnaker GCR service account
resource "google_service_account_key" "spinnaker_gcr" {
  depends_on = [
    "google_project_iam_binding.role_browser",
    "google_project_iam_binding.role_storage_admin",
  ]

  service_account_id = "${google_service_account.spinnaker_gcr.name}"
}

data "template_file" "deploy_spinnaker" {
  depends_on = [
    "kubernetes_service_account.spinnaker",
    "google_service_account_key.spinnaker_gcr",
    "google_service_account_key.spinnaker_gcs",
  ]

  template = <<EOF
set -ex \
&& gcloud container clusters --zone=$${zone} --project=$${project} get-credentials $${cluster_name} \
&& kubectl create clusterrolebinding spinnaker-admin --clusterrole=cluster-admin --serviceaccount=$${k8s_namespace}:$${k8s_sa} || true \
&& CONTEXT=$(kubectl config current-context) \
&& SECRET_NAME=$(kubectl get serviceaccount $${k8s_sa} --namespace $${k8s_namespace} -o jsonpath='{.secrets[0].name}') \
&& TOKEN=$(kubectl get secret --namespace $${k8s_namespace} $SECRET_NAME -o yaml  -o jsonpath='{.data.token}' | base64 --decode) \
&& kubectl config set-credentials $CONTEXT-token-user --token $TOKEN \
&& kubectl config set-context $CONTEXT --user $CONTEXT-token-user \
&& kubectl --namespace=default patch serviceaccount default -p '{"imagePullSecrets": [{"name": "gcr-json-key"}]}' || true \
&& GCS_ACCOUNT_JSON_FILE=/tmp/.gcs-account.json \
&& GCR_ACCOUNT_JSON_FILE=/tmp/.gcr-account.json \
&& echo '$${gcs_account_json}' | base64 --decode > $GCS_ACCOUNT_JSON_FILE \
&& echo '$${gcr_account_json}' | base64 --decode > $GCR_ACCOUNT_JSON_FILE \
&& kubectl --namespace=default delete secret gcr-json-key || true \
&& kubectl --namespace=default create secret docker-registry gcr-json-key \
      --docker-server=gcr.io \
      --docker-username=_json_key \
      --docker-password="$(cat $GCR_ACCOUNT_JSON_FILE)" \
      --docker-email=any@valid.email \
&& kubectl --namespace $${k8s_namespace} apply -f redis-deployment.yaml \
&& rm -f /opt/halyard/pid \
&& hal -q config provider docker-registry account delete my-gcr-registry --no-validate || true \
&& hal -q config provider docker-registry account add my-gcr-registry --address 'gcr.io' --username _json_key --password-file $GCR_ACCOUNT_JSON_FILE \
&& hal -q config provider docker-registry enable \
&& echo hal -q config provider kubernetes account add my-k8s-v2-account  --provider-version v2 --context $(kubectl config current-context) \
&& hal -q config provider kubernetes account delete my-k8s-account --no-validate || true \
&& hal -q config provider kubernetes account add my-k8s-account --docker-registries my-gcr-registry --context $(kubectl config current-context) \
&& hal -q config provider kubernetes enable \
&& hal -q config storage gcs edit --project $${project} --bucket-location $${gcs_location} --json-path $GCS_ACCOUNT_JSON_FILE --bucket $${bucket} \
&& hal -q config storage edit --type gcs \
&& hal -q config canary google account delete my-google-account --no-validate || true \
&& hal -q config canary google account add my-google-account --project $${project} --json-path $GCS_ACCOUNT_JSON_FILE --bucket $${bucket} \
&& hal -q config canary google enable \
&& hal -q config canary google edit --gcs-enabled true --stackdriver-enabled true \
&& hal -q config canary edit --default-metrics-store stackdriver \
&& hal -q config canary enable \
&& hal -q config version edit --version $(hal version latest -q) \
&& hal -q config features edit --artifacts true --pipeline-templates true \
&& hal -q config deploy edit --type distributed --account-name my-k8s-account \
&& [[ -d /home/hal/.hal ]] && HAL_ROOT=/home/hal/.hal || true \
&& [[ -z "$HAL_ROOT" ]] && HAL_ROOT=$HOME/.hal || true \
&& SETT_DIR=$HAL_ROOT/default/service-settings \
&& mkdir -p $SETT_DIR \
&& SETT_FILE=$SETT_DIR/redis.yml \
&& echo "overrideBaseUrl: $${redis_url}" > $SETT_FILE \
&& echo "skipLifeCycleManagement: true" >> $SETT_FILE \
&& hal -q deploy apply
EOF

  vars {
    k8s_namespace    = "${kubernetes_service_account.spinnaker.metadata.0.namespace}"
    k8s_sa           = "${kubernetes_service_account.spinnaker.metadata.0.name}"
    zone             = "${var.zone}"
    cluster_name     = "${var.cluster_name}"
    project          = "${var.project}"
    gcs_location     = "${var.gcs_location}"
    bucket           = "${google_storage_bucket.spinnaker_config.name}"
    gcs_account_json = "${google_service_account_key.spinnaker_gcs.private_key}"
    gcr_account_json = "${google_service_account_key.spinnaker_gcr.private_key}"
    redis_url        = "redis://:redis@ext-redis-master.spinnaker:6379"
  }
}

resource "null_resource" "deploy_spinnaker" {
  depends_on = [
    "google_service_account_key.spinnaker_gcr",
  ]

  triggers {
    cksum = "${sha256(data.template_file.deploy_spinnaker.template)}"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "${data.template_file.deploy_spinnaker.rendered}"
  }
}
