
# Cloud Function Setup Module

This module sets up a Google Cloud Function, a topic and a cloud scheduled task
to automatically downgrade owners to iam admins periodically.

## Usage

```hcl
module "auto_unsudo_setup" {
  source = "./terraform"

  bucket_name           = "${var.project}-cloudfunction-deploy-${var.env}"
  bucket_location       = "US"
  topic_name            = "sysadm-topic"
  function_name         = "my-cloud-function"
  function_description  = "This is a description for my cloud function"
  runtime               = "python39"
  memory                = 256
  entry_point           = "my_entry_point"
  ingress_settings      = "ALLOW_INTERNAL_ONLY"
  service_account_name  = "my-cloud-function-sa"
  project               = "my-gcp-project-id"
  command               = "MY_COMMAND"
  max_instances         = 1
  job_name              = "my-scheduler-job"
  job_description       = "This is a description for my scheduler job"
  schedule              = "0 6,19,22,1,3 * * *"
}

# To access the outputs from the module:
output "deployed_bucket_name" {
  value = module.cloud_function_setup.bucket_name
}

output "deployed_topic_name" {
  value = module.cloud_function_setup.topic_name
}

# ... Similarly for other outputs ...
```