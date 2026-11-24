variable "name" {
  description = "Name of the IAM application."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "description" {
  description = "Description of the IAM application."
  type        = string
  default     = null
}

variable "organization_id" {
  description = "Scaleway organization ID for the application. The policy always uses the application's organization. If null, the Scaleway provider default is used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the application and its policy."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "policy_rules" {
  description = "Rules for an IAM policy attached to the application. Each rule grants permission_set_names on either project_ids or organization_id, never both, with an optional condition. The policy is created only when this list is not empty."
  type = list(object({
    permission_set_names = set(string)
    project_ids          = optional(list(string))
    organization_id      = optional(string)
    condition            = optional(string)
  }))
  default  = []
  nullable = false

  validation {
    condition     = alltrue([for rule in var.policy_rules : length(rule.permission_set_names) > 0])
    error_message = "Each policy rule must grant at least one permission set."
  }

  validation {
    condition     = alltrue([for rule in var.policy_rules : (rule.project_ids != null) != (rule.organization_id != null)])
    error_message = "Each policy rule must be scoped to exactly one of project_ids or organization_id."
  }

  validation {
    condition     = alltrue([for rule in var.policy_rules : rule.project_ids == null ? true : length(rule.project_ids) > 0])
    error_message = "A policy rule's project_ids must not be empty; use organization_id for an organization-wide rule."
  }
}

variable "policy_name" {
  description = "Name of the application's IAM policy. If null, name is used. Ignored when policy_rules is empty."
  type        = string
  default     = null
}

variable "policy_description" {
  description = "Description of the application's IAM policy. Ignored when policy_rules is empty."
  type        = string
  default     = null
}

variable "api_keys" {
  description = "API keys for the application, keyed by a stable label. The description defaults to \"<name>: <label>\". Renaming a label, or changing expires_at or secret_id, replaces the key and issues a new secret. Set secret_id to an existing Scaleway Secret Manager secret to store the secret key there instead of in state."
  type = map(object({
    description        = optional(string)
    default_project_id = optional(string)
    expires_at         = optional(string)
    secret_id          = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for label in keys(var.api_keys) : length(trimspace(label)) > 0])
    error_message = "api_keys labels must not be empty."
  }

  validation {
    condition     = alltrue([for key in values(var.api_keys) : key.expires_at == null ? true : can(formatdate("YYYY", key.expires_at))])
    error_message = "api_keys expires_at must be an RFC 3339 timestamp, such as 2027-01-01T00:00:00Z."
  }
}

variable "group_ids" {
  description = "IAM groups the application joins, keyed by a stable label with the group ID as the value. Labels must be known at plan time; group IDs may come from resources in the same configuration."
  type        = map(string)
  default     = {}
  nullable    = false
}
