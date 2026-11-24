# Working on this module

This repository contains an OpenTofu module that creates a Scaleway IAM
application, with an optional policy, API keys, and group memberships. Keep
changes focused and use the Taskfile as the entry point for local and CI work.

## Commands

Run `task --list` before choosing a task. The normal verification command is
`task ci`; it runs formatting, OpenTofu validation, TFLint, terraform-docs, and
native OpenTofu tests. `task docs` and `task docs:check` use the pinned
terraform-docs Docker image; do not add a local terraform-docs installation.
`task lint` uses the pinned TFLint Docker image; do not add a local TFLint
installation.
Use `task docs` after changing inputs, outputs, provider constraints, or
resource declarations. It regenerates the marked section of `README.md`; do
not hand-edit that section.

`task test:native` runs native OpenTofu tests with a mocked Scaleway provider
and `command = plan`. It must never gain an apply, destroy, real key, state
file, or production fixture. Tests should assert a user-visible resource
contract from the plan. CI uses the version in `.opentofu-version`. See
[docs/testing.md](docs/testing.md) before adding Terratest or a real-cloud
integration test.

Use `task release:check` to run all checks and preview the next release. Use
`task release` only from a clean `main` checkout with a
`SEMREL_PLUGIN_TOKEN` GitHub credential; it can write `CHANGELOG.md`, create
and push a Git tag, and create a GitHub release. semrel derives versions from
Conventional Commit messages.

## OpenTofu conventions

- Keep the root module compatible with OpenTofu `>= 1.12.0, < 2.0.0` and the
  Scaleway provider `~> 2.88` unless a deliberate compatibility change is
  documented. 2.88 is the first provider release with the API key
  `secret_id` argument.
- The policy is gated with `count` on `policy_rules` being non-empty; API keys
  and group memberships use `for_each` over user-supplied labels. Do not
  rename `scaleway_iam_application.this`, `scaleway_iam_policy.this`,
  `scaleway_iam_api_key.this`, or `scaleway_iam_group_membership.this`
  without a `moved` block. A replaced API key issues a new secret and revokes
  the old one, so treat any change that replaces keys as breaking.
- API secret keys leave the module only through the sensitive
  `api_key_secret_keys` output, and never for keys with `secret_id`. Do not add
  another output, local file, or log line that exposes them.
- Policy rules must keep exactly one scope (`project_ids` or
  `organization_id`). Do not add a default that widens a rule's scope.
- Keep input descriptions clear, add validation when it prevents a known
  provider failure or an unsafe grant, and mark secret-derived outputs
  `sensitive`.
- Examples are independently linted OpenTofu roots. Give each example its own
  OpenTofu and provider constraints, and keep them valid with the current
  provider schema.
- Do not commit `.terraform/`, `.tofu/`, `.terraform.lock.hcl`, `.tofu.lock.hcl`,
  state, plans, provider credentials, or semrel plugin binaries.

## Change discipline

Use Conventional Commit messages. Run the smallest relevant Task targets while
editing, then `task ci` before handing off. Make a focused commit for each
independent milestone. If an interruption leaves work incomplete, update
`TODO.md` with the actual remaining verification or implementation work.
