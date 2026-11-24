output "application_id" {
  description = "ID of the IAM application."
  value       = scaleway_iam_application.this.id
}

output "application_name" {
  description = "Name of the IAM application."
  value       = scaleway_iam_application.this.name
}

output "organization_id" {
  description = "Scaleway organization ID associated with the IAM application."
  value       = scaleway_iam_application.this.organization_id
}

output "policy_id" {
  description = "ID of the application's IAM policy, or null when policy_rules is empty."
  value       = one(scaleway_iam_policy.this[*].id)
}

output "api_keys" {
  description = "Non-secret API key attributes keyed by api_keys label."
  value = {
    for label, key in scaleway_iam_api_key.this : label => {
      access_key         = key.access_key
      default_project_id = key.default_project_id
      expires_at         = key.expires_at
    }
  }
}

output "api_key_secret_keys" {
  description = "API secret keys keyed by api_keys label. Keys with secret_id are omitted because their secret is written to Secret Manager, not state."
  value = {
    for label, key in scaleway_iam_api_key.this : label => key.secret_key
    if var.api_keys[label].secret_id == null
  }
  sensitive = true
}
