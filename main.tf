locals {
  policy_name = coalesce(var.policy_name, var.name)
  tags        = tolist(var.tags)
}

resource "scaleway_iam_application" "this" {
  description     = var.description
  name            = var.name
  organization_id = var.organization_id
  tags            = local.tags
}

resource "scaleway_iam_policy" "this" {
  count = length(var.policy_rules) > 0 ? 1 : 0

  application_id  = scaleway_iam_application.this.id
  description     = var.policy_description
  name            = local.policy_name
  organization_id = scaleway_iam_application.this.organization_id
  tags            = local.tags

  dynamic "rule" {
    for_each = var.policy_rules

    content {
      condition            = rule.value.condition
      organization_id      = rule.value.organization_id
      permission_set_names = rule.value.permission_set_names
      project_ids          = rule.value.project_ids
    }
  }
}

resource "scaleway_iam_group_membership" "this" {
  for_each = var.group_ids

  application_id = scaleway_iam_application.this.id
  group_id       = each.value
}

resource "scaleway_iam_api_key" "this" {
  for_each = var.api_keys

  application_id     = scaleway_iam_application.this.id
  default_project_id = each.value.default_project_id
  description        = coalesce(each.value.description, "${var.name}: ${each.key}")
  expires_at         = each.value.expires_at
  secret_id          = each.value.secret_id
}
