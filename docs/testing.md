# Testing strategy

## Execution assumptions

The module supports OpenTofu `>= 1.12.0, < 2.0.0`; CI uses the version in
`.opentofu-version` and Scaleway provider `~> 2.88`. It is a reusable leaf
module, so it has no backend or state of its own. Checks run through
`Taskfile.yml`.

## Decision matrix

| Situation in this module | Tool | Current decision | Reason |
| --- | --- | --- | --- |
| Formatting, schema, and static checks | `task fmt:check`, `task validate`, TFLint | Use | Free checks catch syntax, schema, and style regressions. |
| Application, policy, API key, and group membership contract; input validation | `tofu test` with `mock_provider` | Use | Inputs, resource shape, and principal wiring are known during `plan`; no credentials or cloud resources are needed. |
| Permission set names, rule conditions, key issuance, Secret Manager writes, or key replacement | Controlled integration test | Do not run by default | These are validated by the Scaleway API and need a dedicated organization or project, a reviewed apply, and reliable cleanup. Real API keys are credentials. |
| Multi-provider orchestration or Go-owned integration harness | Terratest | Do not use now | This module has one provider and no integration behavior that native mocked tests cannot cover. |

Mocked tests cannot prove that a permission set name exists or that a policy
condition is accepted; the provider sends both to the API unchanged. Review
the plan of a real root configuration for those.

`task test:native` and `task ci` do not apply or destroy infrastructure.
Before a real integration test or any production change, run a reviewed
`tofu plan -out=tfplan` in the target root, retain the plan artifact, and apply
that exact reviewed artifact only after approval. An integration test must
use a disposable organization or project, tag every resource, never print
`api_key_secret_keys`, and destroy its API keys in cleanup.
