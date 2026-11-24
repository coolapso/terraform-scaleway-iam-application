![CI](https://github.com/coolapso/terraform-scaleway-iam-application/actions/workflows/ci.yml/badge.svg?branch=main)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-1F6FEB?logo=opentofu)](https://opentofu.org/)

# OpenTofu Scaleway IAM Application

An OpenTofu module for one Scaleway IAM application: a non-human principal for
workloads, CI jobs, and operators such as external-dns or cert-manager. It can
also create the application's IAM policy, API keys, and group memberships.
Each of those is opt-in.

Requires OpenTofu 1.12 or later and Scaleway provider 2.88 or later. The
module does not configure a backend or provider credentials.

## Usage

```hcl
module "external_dns" {
  source = "coolapso/iam-application/scaleway"

  name        = "external-dns"
  description = "Manages DNS records for Kubernetes services."
  tags        = ["kubernetes", "dns"]

  policy_rules = [
    {
      permission_set_names = ["DomainsDNSFullAccess"]
      project_ids          = [var.project_id]
    },
  ]

  api_keys = {
    kubernetes = {
      default_project_id = var.project_id
      expires_at         = "2027-12-31T00:00:00Z"
    }
  }
}
```

See the [OpenTofu example](./examples/opentofu), [Terragrunt example](./examples/terragrunt),
and [testing strategy](./docs/testing.md).

### Policy rules

The module creates one policy, attached to the application, when
`policy_rules` is not empty. The policy is named after the application unless
`policy_name` is set, and it is always created in the application's
organization. Each rule must be scoped to exactly one of `project_ids` or
`organization_id`, so an organization-wide grant is always an explicit choice.
Use the optional `condition` to restrict a rule further, for example by
source IP.

Permission set names and conditions are passed to the Scaleway API unchanged;
check them against the Scaleway IAM documentation and review the plan.

### API keys and secret handling

`api_keys` is a map keyed by a stable label. A key's description defaults to
`<name>: <label>`. `api_keys` exposes each key's access key, which identifies
the key and is not a secret.

The secret key is returned once by Scaleway, at creation. Where it goes depends
on `secret_id`:

- **Without `secret_id`**, the provider stores the secret key in state, and the
  module returns it in the sensitive `api_key_secret_keys` output. Treat the
  state backend as a secret store: encrypt it and restrict access to it.
- **With `secret_id`**, the provider writes the secret key as a new version of
  an existing Scaleway Secret Manager secret and does not store it in state.
  The key is omitted from `api_key_secret_keys`. The module does not manage
  the secret itself.

```hcl
resource "scaleway_secret" "ci_api_key" {
  name = "ci-api-key"
}

module "ci" {
  source = "coolapso/iam-application/scaleway"

  name = "ci"

  api_keys = {
    deploy = {
      secret_id  = scaleway_secret.ci_api_key.id
      expires_at = "2027-06-30T00:00:00Z"
    }
  }
}
```

Changing a key's label, `expires_at`, or `secret_id` replaces the key, and the
old secret stops working when the replacement is applied. To rotate without an
outage, add a new label, move consumers to the new key, then remove the old
label. Set `expires_at` so forgotten keys stop working.

### Group memberships

`group_ids` adds the application to existing IAM groups. Key it by a label
known at plan time; the group IDs themselves can come from resources in the
same configuration.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0, < 2.0.0 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.88 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.88 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_iam_api_key.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_api_key) | resource |
| [scaleway_iam_application.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_application) | resource |
| [scaleway_iam_group_membership.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_group_membership) | resource |
| [scaleway_iam_policy.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_keys"></a> [api\_keys](#input\_api\_keys) | API keys for the application, keyed by a stable label. The description defaults to "<name>: <label>". Renaming a label, or changing expires\_at or secret\_id, replaces the key and issues a new secret. Set secret\_id to an existing Scaleway Secret Manager secret to store the secret key there instead of in state. | <pre>map(object({<br/>    description        = optional(string)<br/>    default_project_id = optional(string)<br/>    expires_at         = optional(string)<br/>    secret_id          = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the IAM application. | `string` | `null` | no |
| <a name="input_group_ids"></a> [group\_ids](#input\_group\_ids) | IAM groups the application joins, keyed by a stable label with the group ID as the value. Labels must be known at plan time; group IDs may come from resources in the same configuration. | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the IAM application. | `string` | n/a | yes |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | Scaleway organization ID for the application. The policy always uses the application's organization. If null, the Scaleway provider default is used. | `string` | `null` | no |
| <a name="input_policy_description"></a> [policy\_description](#input\_policy\_description) | Description of the application's IAM policy. Ignored when policy\_rules is empty. | `string` | `null` | no |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | Name of the application's IAM policy. If null, name is used. Ignored when policy\_rules is empty. | `string` | `null` | no |
| <a name="input_policy_rules"></a> [policy\_rules](#input\_policy\_rules) | Rules for an IAM policy attached to the application. Each rule grants permission\_set\_names on either project\_ids or organization\_id, never both, with an optional condition. The policy is created only when this list is not empty. | <pre>list(object({<br/>    permission_set_names = set(string)<br/>    project_ids          = optional(list(string))<br/>    organization_id      = optional(string)<br/>    condition            = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the application and its policy. | `set(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_key_secret_keys"></a> [api\_key\_secret\_keys](#output\_api\_key\_secret\_keys) | API secret keys keyed by api\_keys label. Keys with secret\_id are omitted because their secret is written to Secret Manager, not state. |
| <a name="output_api_keys"></a> [api\_keys](#output\_api\_keys) | Non-secret API key attributes keyed by api\_keys label. |
| <a name="output_application_id"></a> [application\_id](#output\_application\_id) | ID of the IAM application. |
| <a name="output_application_name"></a> [application\_name](#output\_application\_name) | Name of the IAM application. |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | Scaleway organization ID associated with the IAM application. |
| <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id) | ID of the application's IAM policy, or null when policy\_rules is empty. |
<!-- END_TF_DOCS -->

## Contributing

Run `task --list` to discover formatting, linting, documentation, test, CI,
and release tasks. The checks run by GitHub Actions are the same Task targets
that run locally.

The local toolchain is OpenTofu, Docker, Task, and semrel. `task docs` and
`task lint` use pinned containers, so terraform-docs and TFLint are not
installed locally. Install the version in `.opentofu-version`. `task ci` does
not create cloud resources: native OpenTofu tests use a mocked provider and
`command = plan`.
`task release:check` previews the release, while `task release` creates the
tag, changelog commit, and GitHub release. Set `SEMREL_PLUGIN_TOKEN` to a
GitHub token with repository write access before a real local release.
