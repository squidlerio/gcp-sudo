# GCP Sudo & Unsudo Scripts

These scripts allow users to elevate their permissions (`sudo`) and revert them back (`unsudo`) within a Google Cloud Platform project.

## Sudo Script

The `sudo` script grants the user the `roles/owner` role for a specific GCP project. This allows the user to have elevated permissions and perform actions that might require owner-level access.

### Usage

```bash
./sudo.sh [PROJECT_ID]
```

`PROJECT_ID` (optional): The ID of the GCP project. If not provided, the script will list the projects you have access to and prompt you to select one.

### Example

```
./sudo.sh my-gcp-project-id
```


## Unsudo Script
The unsudo script reverts the permissions granted by the sudo script. It removes the roles/owner role from the user and assigns the roles/resourcemanager.projectIamAdmin role to ensure the user still has IAM management capabilities.

### Usage

```bash
./unsudo.sh [PROJECT_ID]
```

### Example

```
./unsudo.sh my-gcp-project-id

```

## Requirements

* Google Cloud SDK (gcloud command-line tool)
* Appropriate permissions to modify IAM policies in the GCP project

## Notes

* Always ensure you understand the implications of changing IAM roles and permissions.
* It's recommended to test these scripts in a non-production environment first.
