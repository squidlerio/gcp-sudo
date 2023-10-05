data "archive_file" "add_iam_admin_role_source_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/add_iam_admin_role"
  output_path = "${path.module}/build/add_iam_admin_role.zip"
  excludes = ["*.terraform*"]
}

data "archive_file" "remove_owner_role_source_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/remove_owner_role"
  output_path = "${path.module}/build/remove_owner_role.zip"
  excludes = ["*.terraform*"]

}

resource "google_storage_bucket" "source_bucket" {
  name     = var.source_bucket_name
  location = var.bucket_location
}

resource "google_storage_bucket_object" "add_iam_admin_role_source" {
  name   = "functions/add_iam_admin_role.zip"
  bucket = google_storage_bucket.source_bucket.name
  source = data.archive_file.add_iam_admin_role_source_zip.output_path
}

resource "google_storage_bucket_object" "remove_owner_role_source" {
  name   = "functions/remove_owner_role.zip"
  bucket = google_storage_bucket.source_bucket.name
  source = data.archive_file.remove_owner_role_source_zip.output_path
}

resource "google_service_account" "unsudo_sa" {
  account_id   = "unsudo"
  display_name = "Unsudo Service Account for Cloud Functions"
  description  = "This service account is used by the Cloud Functions to unsudo permissions."
}

resource "google_project_iam_member" "function_invoker" {
  project = var.project_id
  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.unsudo_sa.email}"
}

resource "google_project_iam_member" "service_account_user" {
  project = var.project_id
  role   = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.unsudo_sa.email}"
}

resource "google_project_iam_member" "iam_admin" {
  role   = "roles/resourcemanager.projectIamAdmin"
  member = "serviceAccount:${google_service_account.unsudo_sa.email}"
  project = var.project_id
}

resource "google_cloudfunctions2_function" "add_iam_admin_role" {
  name        = var.add_iam_admin_role_function_name
  description = "Function to add IAM admin role to owners"
  location= var.workflow_region
  build_config {
    runtime     = "python310"
    entry_point = "add_iam_admin_role_for_owners"
    source {
      storage_source {
        bucket = var.source_bucket_name
        object = google_storage_bucket_object.add_iam_admin_role_source.name
      }
    }
  }

  service_config {
    available_memory    = "128Mi"
    timeout_seconds     = 60
    ingress_settings    = "ALLOW_INTERNAL_ONLY"
    service_account_email = google_service_account.unsudo_sa.email
  }
}

resource "google_cloudfunctions2_function" "remove_owner_role" {
  name        = var.remove_owner_role_function_name
  description = "Function to remove owner role"
  location= var.workflow_region
  build_config {
    runtime     = "python310"
    entry_point = "remove_owner_role"
    source {
      storage_source {
        bucket = var.source_bucket_name
        object = google_storage_bucket_object.remove_owner_role_source.name
      }
    }
  }

  service_config {
    available_memory    = "128Mi"
    timeout_seconds     = 60
    ingress_settings    = "ALLOW_INTERNAL_ONLY"
    service_account_email = google_service_account.unsudo_sa.email
  }
}



resource "google_workflows_workflow" "iam_workflow" {
  name     = var.workflow_name
  region   = var.workflow_region
  service_account = google_service_account.unsudo_sa.email

  source_contents = <<-EOT
  - initialize:
      assign:
        - project: ${var.project_id}
        - add_iam_admin_role_function_url: ${google_cloudfunctions2_function.add_iam_admin_role.service_config[0].uri}
        - remove_owner_role_function_url: ${google_cloudfunctions2_function.remove_owner_role.service_config[0].uri}
  - add_iam_admin_role:
      call: http.get
      args:
        url: ${google_cloudfunctions2_function.add_iam_admin_role.service_config[0].uri}
        auth:
          type: OIDC
          audience: ${google_cloudfunctions2_function.add_iam_admin_role.service_config[0].uri}
      result: add_iam_admin_role_result
  - remove_owner_role:
      call: http.get
      args:
        url: ${google_cloudfunctions2_function.remove_owner_role.service_config[0].uri}
        auth:
          type: OIDC
          audience: ${google_cloudfunctions2_function.remove_owner_role.service_config[0].uri}
      result: remove_owner_role_result
  - final:
      return: "Workflow completed"
  EOT
}

resource "google_cloudfunctions2_function_iam_member" "add_iam_admin_role_invoker" {
  project = var.project_id
  cloud_function = google_cloudfunctions2_function.add_iam_admin_role.name
  location = var.workflow_region
  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.unsudo_sa.email}"
}

resource "google_cloudfunctions2_function_iam_member" "remove_owner_role_invoker" {
  project = var.project_id
  location = var.workflow_region
  cloud_function = google_cloudfunctions2_function.remove_owner_role.name
  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.unsudo_sa.email}"
}
resource "google_cloud_run_v2_service_iam_member" "add_iam_admin_role_invoker" {
  project = var.project_id
  location = var.workflow_region
  name        =  google_cloudfunctions2_function.add_iam_admin_role.name
  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.unsudo_sa.email}"
}
resource "google_cloud_run_v2_service_iam_member" "remove_owner_role_invoker" {
  project = var.project_id
  location = var.workflow_region
  name        =  google_cloudfunctions2_function.remove_owner_role.name
  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.unsudo_sa.email}"
}

resource "google_cloud_scheduler_job" "unsudo_scheduler" {
  name             = "unsudo-scheduler"
  description      = "Scheduler to trigger the unsudo workflow"
  schedule         = var.scheduler_frequency
  time_zone        = "UTC"
  attempt_deadline = "360s"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.iam_workflow.id}/executions"
    oauth_token {
      service_account_email = google_service_account.unsudo_sa.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }

    headers = {
      "Content-Type" = "application/octet-stream"
      "User-Agent"   = "Google-Cloud-Scheduler"
      # Add more headers as needed
    }

    body = base64encode(jsonencode({
      argument       = "{}",
      callLogLevel   = "LOG_ERRORS_ONLY"
    }))
  }
}

resource "google_project_iam_member" "workflow_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.unsudo_sa.email}"
}