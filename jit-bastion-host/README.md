<!-- Copyright 2023 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. -->

<!-- BEGIN_TF_DOCS -->
# JIT Bastion Host module

This module is to be applied into a project administered by the jit-access tool (https://github.com/GoogleCloudPlatform/jit-access).

It handles the provisioning of IAM, GCE templates, and Cloud Workflows to provision/deprovision the Bastion Host automatically.

## Requirements

No requirements.

## Providers

| Name                                                       | Version |
| ---------------------------------------------------------- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | n/a     |
| <a name="provider_random"></a> [random](#provider\_random) | n/a     |

## Modules

| Name                                                                              | Source                                                                          | Version |
| --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ------- |
| <a name="module_service-project"></a> [service-project](#module\_service-project) | https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project | n/a     |

## Resources

| Name                                                                                                                                                               | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- |
| [google_cloud_run_v2_job.create-bastion-host](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_job)                     | resource |
| [google_cloud_run_v2_job.delete-bastion-host](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_job)                     | resource |
| [google_compute_firewall.fw-ssh-iap-bastion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall)                      | resource |
| [google_compute_instance_template.bastion-host-template](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template) | resource |
| [google_compute_network.service_vpc_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network)                       | resource |
| [google_project_iam_binding.bastion_iap_frontend_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_binding)       | resource |
| [google_project_iam_binding.bastion_iap_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_binding)                  | resource |
| [google_project_iam_binding.compute_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_binding)                      | resource |
| [google_project_iam_binding.service_project_iam](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_binding)               | resource |
| [google_project_iam_custom_role.compute_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role)              | resource |
| [google_service_account.bastion_host](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account)                              | resource |
| [google_service_account_iam_binding.bastion_sa_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_binding)   | resource |
| [google_workflows_workflow.manage-bastion-host](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workflows_workflow)                 | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string)                                                      | resource |

## Inputs

| Name                                                                                                                                    | Description                              | Type          | Default                               | Required |
| --------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- | ------------- | ------------------------------------- | :------: |
| <a name="input_bastion_compute_use_custom_role"></a> [bastion\_compute\_use\_custom\_role](#input\_bastion\_compute\_use\_custom\_role) | n/a                                      | `string`      | `"bastionComputeUser"`                |    no    |
| <a name="input_bastion_host_name"></a> [bastion\_host\_name](#input\_bastion\_host\_name)                                               | n/a                                      | `string`      | `"bastion-host"`                      |    no    |
| <a name="input_bastion_host_region"></a> [bastion\_host\_region](#input\_bastion\_host\_region)                                         | n/a                                      | `string`      | `"us-central1"`                       |    no    |
| <a name="input_bastion_host_tags"></a> [bastion\_host\_tags](#input\_bastion\_host\_tags)                                               | n/a                                      | `set(string)` | <pre>[<br>  "bastion-host"<br>]</pre> |    no    |
| <a name="input_bastion_host_zone"></a> [bastion\_host\_zone](#input\_bastion\_host\_zone)                                               | n/a                                      | `string`      | `"us-central1-a"`                     |    no    |
| <a name="input_billing_account_id"></a> [billing\_account\_id](#input\_billing\_account\_id)                                            | n/a                                      | `string`      | `null`                                |    no    |
| <a name="input_jit_users"></a> [jit\_users](#input\_jit\_users)                                                                         | a set of users i.e. user:abc@example.com | `set(string)` | n/a                                   |   yes    |
| <a name="input_org_id"></a> [org\_id](#input\_org\_id)                                                                                  | n/a                                      | `string`      | `null`                                |    no    |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account)                                                       | n/a                                      | `string`      | `null`                                |    no    |
| <a name="input_service_project_id"></a> [service\_project\_id](#input\_service\_project\_id)                                            | n/a                                      | `string`      | `null`                                |    no    |
| <a name="input_service_project_name"></a> [service\_project\_name](#input\_service\_project\_name)                                      | n/a                                      | `string`      | `null`                                |    no    |
| <a name="input_service_project_vpc_network"></a> [service\_project\_vpc\_network](#input\_service\_project\_vpc\_network)               | n/a                                      | `string`      | `null`                                |    no    |

## Outputs

No outputs.
<!-- END_TF_DOCS -->