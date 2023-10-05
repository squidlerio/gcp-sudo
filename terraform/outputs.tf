output "workflow_name" {
  description = "Name of the deployed Google Cloud Workflow."
  value       = google_workflows_workflow.iam_workflow.name
}

output "add_iam_admin_role_function_url" {
  description = "URL of the deployed add_iam_admin_role Cloud Function."
  value       = google_cloudfunctions2_function.add_iam_admin_role.service_config[0].uri
}

output "remove_owner_role_function_url" {
  description = "URL of the deployed remove_owner_role Cloud Function."
  value       = google_cloudfunctions2_function.remove_owner_role.service_config[0].uri
}
