#!/bin/bash

# Get the active account
get_active_account() {
  gcloud auth list --filter=status:ACTIVE --format="value(account)"
}

# List all projects the user can see
list_gcp_projects() {
  gcloud projects list --format="value(projectId)"
}

# Set the user as an owner for the selected project
set_owner() {
  local project_id=$1
  local account=$2

  gcloud projects add-iam-policy-binding $project_id \
    --member="user:${account}" --role="roles/owner" --no-user-output-enabled
  echo "You've been set as an owner for project: $project_id"
}

main() {
  local account=$(get_active_account)

  # If a project ID is provided as an argument, use it directly
  if [[ ! -z "$1" ]]; then
    set_owner $1 $account
    exit 0
  fi

  local projects=$(list_gcp_projects)

  echo "Select a project from the list:"
  select project_id in $projects; do
    if [[ -z "$project_id" ]]; then
      echo "Invalid option. Exiting..."
      exit 1
    fi

    set_owner $project_id $account
    break
  done
}

main "$@"
