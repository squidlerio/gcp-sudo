import os
import base64
from apiclient import discovery
from google.auth import default

def add_iam_admin_role_for_owners(request):
    credentials, project_id = default()
    if not project_id:
        return "Error: Project id not found", 500
    service = create_service()
    print("Project: "  +project_id)

    service = create_service()
    print("Project: "  + project_id)
    if not add_iam_admin_role(service, project_id, "roles/owner"):
        return "Failed to make owners IAM admins.", 500

    return "Successfully made owners IAM admins.", 200

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

def add_iam_admin_role(crm_service, project_id, role):
    """Makes all members with the owner role an IAM admin."""
    policy = get_policy(crm_service, project_id)
    binding = next(b for b in policy["bindings"] if b["role"] == role)
    iam_admin_binding = next((b for b in policy["bindings"] if b["role"] == "roles/resourcemanager.projectIamAdmin"), None)

    print(f"Owners in the project {project_id}: {', '.join(binding['members'])}")

    if not iam_admin_binding:
        iam_admin_binding = {"role": "roles/resourcemanager.projectIamAdmin", "members": []}
        policy["bindings"].append(iam_admin_binding)

    for member in binding["members"]:
        if member not in iam_admin_binding["members"]:
            print(f"Making {member} an IAM admin...")
            iam_admin_binding["members"].append(member)

    try:
        set_policy(crm_service, project_id, policy)
        return True
    except Exception as e:
        print(f"Error while making owners IAM admins: {e}")
        return False


if __name__ == "__main__":
    # Simulate a call to the primary function
    result, status_code = add_iam_admin_role_for_owners(None)
    print(f"Result: {result}, Status Code: {status_code}")