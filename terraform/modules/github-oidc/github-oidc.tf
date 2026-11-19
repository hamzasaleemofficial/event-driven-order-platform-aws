module "github_actions_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.0"

  name = var.role_name

  enable_github_oidc = true

  oidc_wildcard_subjects = [
    "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"
  ]

  policies = {}

  tags = var.tags
}