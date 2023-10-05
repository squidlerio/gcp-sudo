import os
from apiclient import discovery
from google.auth import default

def remove_owner_role(request):
    credentials, project_id = default()
    if not project_id:
        return "Error: Project id not found", 500
    service = create_service()
    print("Project: "  +project_id)

    if not remove_owner(service, project_id):
        return "Failed to remove owner role.", 500

    return "Successfully removed owner role.", 200

def create_service():
    """Provides a service using application default credentials."""
    return discovery.build('cloudresourcemanager', 'v1')

def get_policy(crm_service, project_id, version=3):
    """Gets IAM policy for a project."""
    policy = (
        crm_service.projects()
        .getIamPolicy(
            resource=project_id,
            body={"options": {"requestedPolicyVersion": version}},
        )
        .execute()
    )
    return policy

def set_policy(crm_service, project_id, policy):
    """Sets IAM policy for a project."""
    crm_service.projects().setIamPolicy(resource=project_id, body={"policy": policy}).execute()

def has_iam_admin_role(crm_service, project_id, user_email):
    """Checks if the specified user has the IAM admin role."""
    policy = get_policy(crm_service, project_id)
    iam_admin_binding = next((b for b in policy["bindings"] if b["role"] == "roles/resourcemanager.projectIamAdmin"), None)

    # Check if the user is in the IAM admin members list
    if iam_admin_binding and f"user:{user_email}" in iam_admin_binding["members"]:
        return True
    return False

def remove_owner(crm_service, project_id):
    """Removes the owner role."""
    policy = get_policy(crm_service, project_id)
    owner_binding = next((b for b in policy["bindings"] if b["role"] == "roles/owner"), None)

    if owner_binding:
        members_to_remove = []  # List to store members who will have their owner role removed
        for member in owner_binding["members"]:
            user_email = member.split(":")[1]  # Extract email from the "user:email" format
            if has_iam_admin_role(crm_service, project_id, user_email):
                members_to_remove.append(member)
            else:
                print(f"User {user_email} does not have IAM admin role. Refusing to remove owner role.")
                return False

        # Remove the members from the owner role and print their emails
        for member in members_to_remove:
            user_email = member.split(":")[1]
            print(f"Removing owner role for user: {user_email}")
            owner_binding["members"].remove(member)

        set_policy(crm_service, project_id, policy)
        return True
    return False


if __name__ == "__main__":
    # Simulate a call to the primary function
    result, status_code = remove_owner_role(None)
    print(f"Result: {result}, Status Code: {status_code}")
