#!/bin/bash

# Get the active account
get_active_account() {
  gcloud auth list --filter=status:ACTIVE --format="value(account)"
}

# List all projects the user can see
list_gcp_projects() {
  gcloud projects list --format="value(projectId)"
}

# Set the user as an IAM admin and remove the owner role for the selected project
set_iam_admin_and_remove_owner() {
  local project_id=$1
  local account=$2

  # Add IAM admin role
  if ! gcloud projects add-iam-policy-binding $project_id \
    --member="user:${account}" --role="roles/resourcemanager.projectIamAdmin" --no-user-output-enabled; then
    echo "Failed to add IAM admin role. Exiting without removing owner role."
    exit 1
  fi

  # Remove owner role
  gcloud projects remove-iam-policy-binding $project_id \
    --member="user:${account}" --role="roles/owner" --quiet

  echo "You've been set as an IAM admin and removed as an owner for project: $project_id"
}

main() {
  local account=$(get_active_account)

  # If a project ID is provided as an argument, use it directly
  if [[ ! -z "$1" ]]; then
    set_iam_admin_and_remove_owner $1 $account
    exit 0
  fi

  local projects=$(list_gcp_projects)

  echo "Select a project from the list:"
  select project_id in $projects; do
    if [[ -z "$project_id" ]]; then
      echo "Invalid option. Exiting..."
      exit 1
    fi

    set_iam_admin_and_remove_owner $project_id $account
    break
  done
}

main "$@"
