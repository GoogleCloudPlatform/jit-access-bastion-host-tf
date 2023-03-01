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
  type = string
}

variable "jit_project_id" {
  type    = string
  default = null
}

variable "jit_region" {
  type    = string
  default = "us-central1"
}

variable "jit_zone" {
  type    = string
  default = "us-central1-a"
}

variable "jit_support_email" {
  type = string
}

variable "jit_elevate_duration" {
  type    = number
  default = 120
}

variable "jit_service_account" {
  type    = string
  default = null
}

variable "billing_account_id" {
  type    = string
  default = null
}

variable "org_wide_list_of_jit_users_groups" {
  type        = set(string)
  description = "i.e. user:abc@example.com, serviceAccount:...-compute@developer.gserviceaccount.com, group:jit-users@example.com"
}
