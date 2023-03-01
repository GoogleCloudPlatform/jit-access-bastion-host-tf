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

# Just-in-time Access requests (+ Bastion Host for log/kubectl/gcloud/curl/etc access)

GCP Customers can enable teams with a Just-in-Time approval mechanism to projects in their cloud organizations.

Features:

1. manage which users can request which project IAM role bindings ahead of support / break glass events
2. allow deployment of pre-baked bastion host images specific to your project needs and configure the networking / firewall security settings ahead of time
3. automatically provision/destroy the bastion host in accordance with the configured timeouts
4. all elevated access requests and activities are logged, audited, and associated directly with the user performing these actions
5. gracefully support IAM access solutions from Terraform, GCDS, or other Google Groups management workflows
6. support self-approved access requests or multi-party approvals via the [JIT access tool](https://github.com/GoogleCloudPlatform/jit-access)

## High Level Architecture Overview for JIT+Bastion Host

In this diagram, an example project is drawn out with supporting architecture to highlight the proposed configuration.

![JIT diagram](jit-access.svg)

## Getting Started

1. Create users, add `has({}.jitAccessConstraint)` conditional IAM to project role bindings for users to be eligible (or the multiparty constraint, per docs)

   Follow the instructions at [JIT access tool](https://github.com/GoogleCloudPlatform/jit-access) to make roles requestable by a user.

   You can choose your mechanism to administer users (Google and Workspace terraform providers, API, Google Consoles, GCDS, etc).

2. Apply the terraform here after filling out the tfvars
3. Grant access to allow the application to resolve group memberships

   The "Groups Reader" role for the service account must be applied in the Google Admin console, which could be done with the Google Workspace provider.

   The Just-In-Time Access application lets you grant eligible access to a specific user or to an entire group. To evaluate group memberships, the application must be allowed to read group membership information from your Cloud Identity or Google Workspace account.

   To grant the application's service account access permission to read group memberships, do the following:

   1. Open the [Google Admin console](https://admin.google.com/) and sign in as a super-admin user.
   2. Go to Account > Admin Roles > Groups Reader > Admins > Assign service accounts and enter `jitaccess@$PROJECT_ID.iam.gserviceaccount.com` where $PROJECT_ID is the ID emitted from `tf apply`. Click "Add" and "Asign role".
