locals {
  project_id = "11111111-1111-1111-1111-111111111111"
}

module "external_dns" {
  source = "../../"

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

output "access_key" {
  description = "Access key for the external-dns API key."
  value       = module.external_dns.api_keys["kubernetes"].access_key
}

output "secret_key" {
  description = "Secret key for the external-dns API key."
  value       = module.external_dns.api_key_secret_keys["kubernetes"]
  sensitive   = true
}
