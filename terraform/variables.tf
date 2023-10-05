variable "add_iam_admin_role_function_name" {
  description = "Name of the Cloud Function to add IAM admin role to owners."
  type        = string
  default     = "add-iam-admin-role-function"
}

variable "remove_owner_role_function_name" {
  description = "Name of the Cloud Function to remove owner role."
  type        = string
  default     = "remove-owner-role-function"
}

variable "source_bucket_name" {
  description = "Name of the GCS bucket containing the zipped source code for the Cloud Functions."
  type        = string
}

variable "workflow_name" {
  description = "Name of the Google Cloud Workflow."
  type        = string
  default     = "iam-modification-workflow"
}

variable "workflow_region" {
  description = "Region where the Google Cloud Workflow will be deployed."
  type        = string
  default     = "europe-west1"
}

variable "project_id" {
  description = "The ID of the project in which resources will be deployed."
  type        = string
}


variable "bucket_location" {
  description = "Location where the GCS bucket will be created."
  type        = string
  default     = "US"  # You can set a default or require it to be passed in every time
}

variable "scheduler_frequency" {
  description = "Cron schedule for the Cloud Scheduler job."
  default     = "0 * * * *"
  type        = string
}