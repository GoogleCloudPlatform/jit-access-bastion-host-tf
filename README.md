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

# Just-in-time Access + Bastion Host

This repository attempts to add on to the features provided by https://github.com/GoogleCloudPlatform/jit-access/.

There are two folders provided, focusing on GCP deployments via Terraform:
1. [jit-app](./jit-app/) provides a TF module for deploying the jit-access tool to it's own project, with some preferred/default configurations.
2. [jit-bastion-host](./jit-bastion-host/) provides a TF module for deploying resources into a project that a team can customize to their own needs wich would allow a controlled bastion-host to be used. This guarantees some level of auditing and access control while prescribing the tools that can be used on a Bastion Host inside a Project and its VPC. This prevents elevated tooling/SSH/log/debugging/database access by teams from their own machines, but unlike solutions such as Hashicorp Boundary and CyberArk, more readily attributes all activity to the user for auditing purposes.

For architectural and other info, dig into the READMEs in each folder.
