
# Cloud Function Setup Module

This module sets up a Google Cloud Function, a topic and a cloud scheduled task
to automatically downgrade owners to iam admins periodically.

## Usage

```hcl
module "my_workflow" {
  source = "./terraform"
  source_bucket_name               = "unsudo-bucket"
  bucket_location = "EU"
  workflow_name                    = "unsudo"
  project_id = var.project
}
```