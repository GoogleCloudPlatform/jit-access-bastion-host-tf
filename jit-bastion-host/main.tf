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



#
# Service Projects Need a Bastion Host,
# a means to deploy it
# and a mechanism to automatically destroy it (after a set timeout)
#

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

module "service-project" {
  count           = var.service_project_id == null ? 1 : 0
  source          = "https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project"
  billing_account = var.billing_account_id
  name            = "${var.service_project_name}-${random_string.suffix.result}"
  services = [
    "artifactregistry.googleapis.com",
    "container.googleapis.com",
    "run.googleapis.com",
    "serviceusage.googleapis.com",
    "compute.googleapis.com",
    "iap.googleapis.com",
    "cloudscheduler.googleapis.com",
    "networkmanagement.googleapis.com",
    "storage.googleapis.com",
    "eventarc.googleapis.com",
    "workflows.googleapis.com",
    "workflowexecutions.googleapis.com"
  ]
}

locals {
  service_project_id = try(module.service-project.project_id, var.service_project_id)
  service_account    = try(module.service-project.service_accounts.default.compute, var.service_account)
}

# for the sake of simplicity here, create a network for the service project in auto mode
resource "google_compute_network" "service_vpc_network" {
  count                   = var.service_project_vpc_network == null ? 1 : 0
  project                 = local.service_project_id
  name                    = "vpc-network"
  auto_create_subnetworks = true
  mtu                     = 1460
}

locals {
  service_project_vpc_network = try(google_compute_network.service_vpc_network.id, var.service_project_vpc_network)
}

resource "google_service_account" "bastion_host" {
  project      = local.service_project_id
  account_id   = "jit-bastion"
  display_name = "SA for Bastion Hosts running in Service Projects"
}

# instance templates should exist in each service project governance, in the event that the service project needs to customize it
resource "google_compute_instance_template" "bastion-host-template" {
  project                 = local.service_project_id
  machine_type            = "custom-4-4096"
  labels                  = {}
  metadata                = { enable-oslogin = "TRUE" }
  tags                    = ["bastion-host"]
  can_ip_forward          = false
  metadata_startup_script = ""
  region                  = "us-central1" # set to appropriate region, but can be overridden when creating instances with the template
  min_cpu_platform        = null
  disk {
    boot         = true
    source_image = "debian-cloud/debian-11"
    labels       = {}
  }
  service_account {
    email  = google_service_account.bastion_host.email
    scopes = ["cloud-platform"]
  }

  network_interface {
    network = local.service_project_vpc_network

    # if using a shared VPC, you may end up using subnet/subnet_project instead
    # subnetwork         = var.subnetwork
    # subnetwork_project = var.subnetwork_project
  }

  lifecycle {
    create_before_destroy = "true"
  }

  scheduling {
    preemptible         = false
    automatic_restart   = true # restart if terminated by compute engine
    on_host_maintenance = "MIGRATE"
  }

  advanced_machine_features {
    enable_nested_virtualization = false
    threads_per_core             = null
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_integrity_monitoring = true
    enable_vtpm                 = true
  }

  confidential_instance_config {
    enable_confidential_compute = false
  }
}

## Cloud Run Job to be triggerable by a JIT'd user to launch a Bastion Host
resource "google_cloud_run_v2_job" "create-bastion-host" {
  name         = "create-bastion-host"
  location     = "us-central1" # set to appropriate region
  launch_stage = "BETA"
  project      = local.service_project_id

  template {
    template {
      containers {
        image = "gcr.io/cloud-builders/gcloud"
        args  = ["compute", "instances", "create", "--source-instance-template", google_compute_instance_template.bastion-host-template.id, "bastion-host", "--zone", "us-central1-a", "--project", local.service_project_id]
      }
    }
  }
}

resource "google_cloud_run_v2_job" "delete-bastion-host" {
  name         = "delete-bastion-host"
  location     = var.bastion_host_region
  launch_stage = "BETA"
  project      = local.service_project_id

  template {
    template {
      containers {
        image = "gcr.io/cloud-builders/gcloud"
        args  = ["compute", "instances", "delete", var.bastion_host_name, "--zone", var.bastion_host_zone, "--project", local.service_project_id]
      }
    }
  }
}

# allow ssh from IAP to bastion-host
resource "google_compute_firewall" "fw-ssh-iap-bastion" {
  project     = local.service_project_id
  name        = "fw-ssh-iap-bastion"
  network     = local.service_project_vpc_network
  description = "Allow SSH/port 22 from Cloud IAP to Bastion Host"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # cloud IAP range
  target_tags   = var.bastion_host_tags
}

#
# IAM for a JIT'd user to use the bastion host
#
# JIT'd users should be able to deploy a bastion-host with the jit-bastion sa attached, and then os-login to the bastion host
# WARNING: authoritative for a given role

resource "google_project_iam_custom_role" "compute_user" {
  role_id     = var.bastion_compute_use_custom_role
  project     = local.service_project_id
  title       = "Compute User Custom Role"
  permissions = ["compute.instances.use"]
}

# bastion SA users (to be able to invoke cloud run / create a compute engine instance)
resource "google_service_account_iam_binding" "bastion_sa_user" {
  service_account_id = google_service_account.bastion_host.id
  role               = "roles/iam.serviceAccountUser"
  members            = var.jit_users
  condition {
    expression = "has({}.jitAccessConstraint)"
    title      = "Requires JIT Access"
  }
}

# allow jit users to access IAP frontend
resource "google_project_iam_binding" "bastion_iap_frontend_access" {
  role    = "roles/iap.httpsResourceAccessor"
  members = var.jit_users
  project = local.service_project_id
}

# allow a user/group access IAP tunnel to the bastion-host
# allow user/group to view/invoke cloud run
# allow os login
# allow to view compute resources
# allow to view logs
resource "google_project_iam_binding" "bastion_iap_user" {
  for_each = toset(["roles/run.viewer", "roles/iap.tunnelResourceAccessor", "roles/compute.osLogin", "roles/compute.viewer", "roles/logging.privateLogViewer", "roles/networkmanagement.admin", "roles/backupdr.computeEngineOperator", "roles/workflows.viewer", "roles/workflows.invoker"])
  # optionally roles/compute.osAdminLogin
  role    = each.value
  project = local.service_project_id
  members = var.jit_users
  condition {
    expression = "has({}.jitAccessConstraint)"
    title      = "Requires JIT Access"
  }
}

resource "google_project_iam_binding" "compute_user" {
  role    = google_project_iam_custom_role.compute_user.name
  project = local.service_project_id
  members = var.jit_users
  condition {
    expression = "has({}.jitAccessConstraint)"
    title      = "Requires JIT Access"
  }

  depends_on = [
    google_project_iam_custom_role.compute_user
  ]
}

#### deprovision Bastion Host after a configured timeout
resource "google_project_iam_binding" "service_project_iam" {
  for_each = toset(["roles/eventarc.eventReceiver", "roles/workflows.invoker"])
  members  = ["serviceAccount:${local.service_account}"]
  role     = each.value
  project  = local.service_project_id
}

resource "google_workflows_workflow" "manage-bastion-host" {
  name            = "manage-bastion-host"
  region          = "us-central1"
  service_account = local.service_account
  project         = local.service_project_id
  source_contents = <<-EOF
  - create_vm:
      call: googleapis.run.v1.namespaces.jobs.run
      args:
          name: namespaces/${local.service_project_id}/jobs/create-bastion-host
          location: us-central1
      result: job_execution
  - wait:
      call: sys.sleep
      args:
        seconds: ${60 * var.jit_elevate_duration}
  - delete_vm:
      call: googleapis.run.v1.namespaces.jobs.run
      args:
          name: namespaces/${local.service_project_id}/jobs/delete-bastion-host
          location: us-central1
      result: job_execution
  - finish:
      return: $${job_execution}
EOF
}
