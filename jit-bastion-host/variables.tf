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


variable "org_id" {
  type    = string
  default = null
}

variable "billing_account_id" {
  type    = string
  default = null
}

variable "jit_users" {
  type        = set(string)
  description = "a set of users i.e. user:abc@example.com"
}

variable "service_project_id" {
  type    = string
  default = null
}

variable "service_account" {
  type    = string
  default = null
}

variable "service_project_name" {
  type    = string
  default = null
}

variable "service_project_vpc_network" {
  type    = string
  default = null
}

variable "bastion_host_zone" {
  type    = string
  default = "us-central1-a"
}

variable "bastion_host_region" {
  type    = string
  default = "us-central1"
}

variable "bastion_host_name" {
  type    = string
  default = "bastion-host"
}

variable "bastion_host_tags" {
  type    = set(string)
  default = ["bastion-host"]
}

variable "bastion_compute_use_custom_role" {
  type    = string
  default = "bastionComputeUser"
}
