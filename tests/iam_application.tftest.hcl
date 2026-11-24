mock_provider "scaleway" {
  mock_resource "scaleway_iam_application" {
    defaults = {
      id              = "11111111-1111-1111-1111-111111111111"
      organization_id = "22222222-2222-2222-2222-222222222222"
    }
  }

  mock_resource "scaleway_iam_policy" {
    defaults = {
      id = "33333333-3333-3333-3333-333333333333"
    }
  }

  mock_resource "scaleway_iam_api_key" {
    defaults = {
      access_key = "SCWNATIVETEST0000000"
      id         = "SCWNATIVETEST0000000"
      secret_key = "44444444-4444-4444-4444-444444444444"
    }
  }

  mock_resource "scaleway_iam_group_membership" {
    defaults = {
      id = "55555555-5555-5555-5555-555555555555/app/11111111-1111-1111-1111-111111111111"
    }
  }
}

run "plans_an_application_without_optional_resources" {
  command = plan

  variables {
    name        = "native-test-application"
    description = "Native test application"
    tags        = ["native-test", "iam"]
  }

  assert {
    condition     = scaleway_iam_application.this.name == "native-test-application"
    error_message = "The application name must be passed to the provider."
  }

  assert {
    condition     = scaleway_iam_application.this.description == "Native test application"
    error_message = "The application description must be passed to the provider."
  }

  assert {
    condition     = scaleway_iam_application.this.tags == tolist(["iam", "native-test"])
    error_message = "Tags must be passed to the application in a stable sorted order."
  }

  assert {
    condition     = length(scaleway_iam_policy.this) == 0 && output.policy_id == null
    error_message = "No policy may be created when policy_rules is empty."
  }

  assert {
    condition     = length(scaleway_iam_api_key.this) == 0 && length(scaleway_iam_group_membership.this) == 0
    error_message = "API keys and group memberships must be opt-in."
  }

  assert {
    condition     = output.application_id == "11111111-1111-1111-1111-111111111111"
    error_message = "application_id must return the provider application ID."
  }

  assert {
    condition     = output.organization_id == "22222222-2222-2222-2222-222222222222"
    error_message = "organization_id must return the provider organization ID."
  }
}

run "plans_a_scoped_policy_for_the_application" {
  command = plan

  variables {
    name = "native-test-application"
    tags = ["native-test"]
    policy_rules = [
      {
        permission_set_names = ["DomainsDNSFullAccess"]
        project_ids          = ["66666666-6666-6666-6666-666666666666"]
      },
      {
        permission_set_names = ["IAMReadOnly"]
        organization_id      = "22222222-2222-2222-2222-222222222222"
      },
    ]
  }

  assert {
    condition     = scaleway_iam_policy.this[0].application_id == "11111111-1111-1111-1111-111111111111"
    error_message = "The policy must be attached to the application."
  }

  assert {
    condition     = scaleway_iam_policy.this[0].organization_id == "22222222-2222-2222-2222-222222222222"
    error_message = "The policy must be created in the application's organization."
  }

  assert {
    condition     = scaleway_iam_policy.this[0].name == "native-test-application"
    error_message = "The policy name must default to the application name."
  }

  assert {
    condition     = scaleway_iam_policy.this[0].tags == tolist(["native-test"])
    error_message = "Tags must be passed to the policy."
  }

  assert {
    condition     = scaleway_iam_policy.this[0].rule[0].project_ids == tolist(["66666666-6666-6666-6666-666666666666"]) && scaleway_iam_policy.this[0].rule[0].organization_id == null
    error_message = "A project-scoped rule must not gain an organization scope."
  }

  assert {
    condition     = scaleway_iam_policy.this[0].rule[1].organization_id == "22222222-2222-2222-2222-222222222222" && scaleway_iam_policy.this[0].rule[1].project_ids == null
    error_message = "An organization-scoped rule must not gain project scopes."
  }

  assert {
    condition     = contains(scaleway_iam_policy.this[0].rule[1].permission_set_names, "IAMReadOnly")
    error_message = "Permission sets must be passed to the policy rule."
  }

  assert {
    condition     = output.policy_id == "33333333-3333-3333-3333-333333333333"
    error_message = "policy_id must return the provider policy ID."
  }
}

run "uses_an_explicit_policy_name" {
  command = plan

  variables {
    name               = "native-test-application"
    policy_name        = "native-test-policy"
    policy_description = "Native test policy"
    policy_rules = [
      {
        permission_set_names = ["ObjectStorageReadOnly"]
        project_ids          = ["66666666-6666-6666-6666-666666666666"]
        condition            = "request.ip in [\"198.51.100.0/24\"]"
      },
    ]
  }

  assert {
    condition     = scaleway_iam_policy.this[0].name == "native-test-policy"
    error_message = "policy_name must override the default policy name."
  }

  assert {
    condition     = scaleway_iam_policy.this[0].description == "Native test policy"
    error_message = "policy_description must be passed to the policy."
  }

  assert {
    condition     = scaleway_iam_policy.this[0].rule[0].condition == "request.ip in [\"198.51.100.0/24\"]"
    error_message = "Rule conditions must be passed to the policy."
  }
}

run "plans_api_keys_and_keeps_secret_manager_keys_out_of_outputs" {
  command = plan

  variables {
    name = "native-test-application"
    api_keys = {
      ci = {
        default_project_id = "66666666-6666-6666-6666-666666666666"
        expires_at         = "2027-01-01T00:00:00Z"
      }
      kubernetes = {
        description = "Kubernetes workload key"
        secret_id   = "fr-par/77777777-7777-7777-7777-777777777777"
      }
    }
  }

  assert {
    condition     = alltrue([for key in scaleway_iam_api_key.this : key.application_id == "11111111-1111-1111-1111-111111111111"])
    error_message = "Every API key must belong to the application."
  }

  assert {
    condition     = scaleway_iam_api_key.this["ci"].description == "native-test-application: ci"
    error_message = "API key descriptions must default to the application name and label."
  }

  assert {
    condition     = scaleway_iam_api_key.this["kubernetes"].description == "Kubernetes workload key"
    error_message = "An explicit API key description must be passed to the provider."
  }

  assert {
    condition     = scaleway_iam_api_key.this["ci"].expires_at == "2027-01-01T00:00:00Z" && scaleway_iam_api_key.this["ci"].default_project_id == "66666666-6666-6666-6666-666666666666"
    error_message = "API key expiry and default project must be passed to the provider."
  }

  assert {
    condition     = scaleway_iam_api_key.this["kubernetes"].secret_id == "fr-par/77777777-7777-7777-7777-777777777777"
    error_message = "secret_id must be passed to the provider."
  }

  assert {
    condition     = output.api_keys["ci"].access_key == "SCWNATIVETEST0000000"
    error_message = "api_keys must expose each access key."
  }

  assert {
    condition     = nonsensitive(keys(output.api_key_secret_keys)) == ["ci"]
    error_message = "api_key_secret_keys must omit keys whose secret is stored in Secret Manager."
  }
}

run "plans_group_memberships" {
  command = plan

  variables {
    name = "native-test-application"
    group_ids = {
      dns-operators = "55555555-5555-5555-5555-555555555555"
    }
  }

  assert {
    condition     = scaleway_iam_group_membership.this["dns-operators"].group_id == "55555555-5555-5555-5555-555555555555"
    error_message = "The group ID must be passed to the membership."
  }

  assert {
    condition     = scaleway_iam_group_membership.this["dns-operators"].application_id == "11111111-1111-1111-1111-111111111111" && scaleway_iam_group_membership.this["dns-operators"].user_id == null
    error_message = "The membership must target the application, not a user."
  }
}

run "rejects_an_empty_name" {
  command = plan

  variables {
    name = " "
  }

  expect_failures = [var.name]
}

run "rejects_a_rule_with_two_scopes" {
  command = plan

  variables {
    name = "native-test-application"
    policy_rules = [
      {
        permission_set_names = ["IAMReadOnly"]
        project_ids          = ["66666666-6666-6666-6666-666666666666"]
        organization_id      = "22222222-2222-2222-2222-222222222222"
      },
    ]
  }

  expect_failures = [var.policy_rules]
}

run "rejects_a_rule_without_a_scope" {
  command = plan

  variables {
    name = "native-test-application"
    policy_rules = [
      {
        permission_set_names = ["IAMReadOnly"]
      },
    ]
  }

  expect_failures = [var.policy_rules]
}

run "rejects_a_rule_with_empty_project_ids" {
  command = plan

  variables {
    name = "native-test-application"
    policy_rules = [
      {
        permission_set_names = ["IAMReadOnly"]
        project_ids          = []
      },
    ]
  }

  expect_failures = [var.policy_rules]
}

run "rejects_a_rule_without_permission_sets" {
  command = plan

  variables {
    name = "native-test-application"
    policy_rules = [
      {
        permission_set_names = []
        project_ids          = ["66666666-6666-6666-6666-666666666666"]
      },
    ]
  }

  expect_failures = [var.policy_rules]
}

run "rejects_an_invalid_api_key_expiry" {
  command = plan

  variables {
    name = "native-test-application"
    api_keys = {
      ci = {
        expires_at = "2027-01-01"
      }
    }
  }

  expect_failures = [var.api_keys]
}
