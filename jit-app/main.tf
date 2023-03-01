# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



# App Engine applications cannot be deleted once they're created; you have to delete the entire project to delete the application. Terraform will report the application has been successfully deleted; this is a limitation of Terraform, and will go away in the future.

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

module "jit-project" {
  count           = var.jit_project_id == null ? 1 : 0
  source          = "https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project"
  billing_account = var.billing_account_id
  name            = "jit-app-${random_string.suffix.result}"
  services = [
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "containeranalysis.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudidentity.googleapis.com",
    "iap.googleapis.com",
    "clouddebugger.googleapis.com",
    "cloudasset.googleapis.com",
    "networkmanagement.googleapis.com",
  ]
}

locals {
  jit_project_id      = try(module.jit-project.project_id, var.jit_project_id)
  jit_service_account = try(module.jit-project.service_accounts.default.compute, var.jit_service_account)
}

###
### IAP
###

resource "google_iap_brand" "jit_brand" {
  support_email     = var.support_email
  application_title = "Cloud IAP protected JIT Access"
  project           = local.jit_project_id
}

resource "google_iap_client" "jit_iap_client" {
  display_name = "JIT Access IAP Client"
  brand        = google_iap_brand.jit_brand.name
}

###
### GAE
###

resource "google_project_iam_member" "jit_gae_api_iam" {
  project = local.jit_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${var.jit_service_account}"
}

resource "google_app_engine_application" "jit_gae_app" {
  project     = local.jit_project_id
  location_id = local.jit_region
  iap {
    enabled              = true
    oauth2_client_id     = google_iap_client.jit_iap_client.client_id
    oauth2_client_secret = google_iap_client.jit_iap_client.secret
  }
}

# If so desired, you can pull the latest code to get JIT app updates
resource "null_resource" "prepare_jit_code" {
  provisioner "local-exec" {
    command     = "rm -rf jit-code jit-code.zip; git clone https://github.com/GoogleCloudPlatform/jit-access jit-code"
    working_dir = path.module
  }
  triggers = {
    "always" = timestamp()
  }
}

data "archive_file" "app-engine-source-zip" {
  type        = "zip"
  source_dir  = "${path.module}/jit-code/sources"
  output_path = "${path.module}/jit-code.zip"
  depends_on = [
    null_resource.prepare_jit_code
  ]
}

resource "google_storage_bucket_object" "app-engine-source-zip-obj" {
  name   = "source-app-engine.${data.archive_file.app-engine-source-zip.output_md5}.zip"
  bucket = google_app_engine_application.jit_gae_app.default_bucket
  source = data.archive_file.app-engine-source-zip.output_path
}

resource "google_app_engine_standard_app_version" "jit_v1" {
  version_id      = "v1"
  service         = "default"
  project         = google_app_engine_application.jit_gae_app.project
  runtime         = "java11"
  instance_class  = "F2"
  service_account = local.jit_service_account
  env_variables = {
    "RESOURCE_SCOPE" : "organizations/${var.org_id}"
    # https://github.com/GoogleCloudPlatform/jit-access/wiki/Configuration
    "ELEVATION_DURATION" : var.jit_elevate_duration # minutes
    "JUSTIFICATION_HINT" : "Bug or case number"
    "JUSTIFICATION_PATTERN" : ".*"
  }
  threadsafe = true
  automatic_scaling {
    max_concurrent_requests = 20
    min_idle_instances      = 0
    min_pending_latency     = "1s"
    max_pending_latency     = "5s"
    standard_scheduler_settings {
      target_cpu_utilization        = 0.5
      target_throughput_utilization = 0.75
      min_instances                 = 0
    }
  }
  delete_service_on_destroy = true
  deployment {
    zip {
      source_url = "https://storage.googleapis.com/${google_app_engine_application.jit_gae_app.default_bucket}/${google_storage_bucket_object.app-engine-source-zip-obj.name}"
    }
  }

  # required block, but for GAE Java it wants empty, for Java 11/17 apps
  entrypoint {
    shell = ""
  }
}

###
### IAM for permissions / IAM mgmt
###

resource "google_project_iam_member" "jit_debugger" {
  project = local.jit_project_id
  role    = "roles/clouddebugger.agent"
  member  = "serviceAccount:${local.jit_service_account}"
}

# You now grant the Security Admin role to the JIT's service account. This role lets the JIT application create temporary IAM bindings when it must grant just-in-time access.

# Because the Security Admin role is highly privileged, you must limit access to the application's service account and to the project that contains it.

resource "google_organization_iam_member" "jit_sa_iam" {
  for_each = toset(["roles/iam.securityAdmin", "roles/cloudasset.viewer"])
  org_id   = var.org_id
  role     = each.value
  member   = "serviceAccount:${local.jit_service_account}"
}

# allow jit users to access IAP frontend
resource "google_project_iam_binding" "bastion_iap_frontend_access" {
  role    = "roles/iap.httpsResourceAccessor"
  members = var.org_wide_list_of_jit_users_groups
  project = local.jit_project_id
}
