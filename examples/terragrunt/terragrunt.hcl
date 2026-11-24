locals {
  project_id = "11111111-1111-1111-1111-111111111111"
}

terraform {
  source = "../../"
}

inputs = {
  name        = "external-dns"
  description = "Manages DNS records for Kubernetes services."
  tags        = ["example", "dns"]

  policy_rules = [
    {
      permission_set_names = ["DomainsDNSFullAccess"]
      project_ids          = [local.project_id]
    },
  ]

  api_keys = {
    kubernetes = {
      default_project_id = local.project_id
      expires_at         = "2027-12-31T00:00:00Z"
    }
  }
}
