
data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "terraform_deployment" {
  statement {
    sid = "PassLambdaExecutionRoles"

    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = var.lambda_execution_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"

      values = [
        "lambda.amazonaws.com"
      ]
    }
  }

  statement {
    sid    = "ManageLambdaExecutionRoles"
    effect = "Allow"

    actions = [
      "iam:GetRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:ListRolePolicies",
      "iam:GetRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListAttachedRolePolicies",
    ]

    resources = var.lambda_execution_role_arns
  }
  statement {
    sid    = "CreateApiLambdaRoleWithBoundary"
    effect = "Allow"

    actions = [
      "iam:CreateRole"
    ]

    resources = [
      var.lambda_execution_role_arns[0]
    ]

    condition {
      test     = "ArnEquals"
      variable = "iam:PermissionsBoundary"

      values = [
        var.lambda_permissions_boundary_arns[0]
      ]
    }
  }

  statement {
    sid    = "CreateWorkerLambdaRoleWithBoundary"
    effect = "Allow"

    actions = [
      "iam:CreateRole"
    ]

    resources = [
      var.lambda_execution_role_arns[1]
    ]

    condition {
      test     = "ArnEquals"
      variable = "iam:PermissionsBoundary"

      values = [
        var.lambda_permissions_boundary_arns[1]
      ]
    }
  }

  statement {
    sid    = "DenyLambdaBoundaryChanges"
    effect = "Deny"

    actions = [
      "iam:DeleteRolePermissionsBoundary",
      "iam:PutRolePermissionsBoundary"
    ]

    resources = var.lambda_execution_role_arns
  }

  statement {
    sid    = "DenyLambdaBoundaryPolicyModification"
    effect = "Deny"

    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:DeletePolicy"
    ]

    resources = var.lambda_permissions_boundary_arns
  }

  statement {
    sid    = "ReadGitHubActionsRole"
    effect = "Allow"

    actions = [
      "iam:GetRole",
      "iam:ListRoleTags",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies"
    ]

    resources = [
      var.github_actions_role_arn
    ]
  }


  statement {
    sid    = "ReadManagedIAMPolicies"
    effect = "Allow"

    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:ListPolicyTags"
    ]

    resources = concat(
      var.lambda_permissions_boundary_arns,
      [
        aws_iam_policy.terraform_backend.arn,
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.github_actions_role_name}-terraform-deployment",
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.github_actions_role_name}-terraform-service-deployment"
      ]
    )
  }

}

resource "aws_iam_policy" "terraform_deployment" {
  name        = "${var.github_actions_role_name}-terraform-deployment"
  description = "Terraform deployment IAM permissions for GitHub Actions"

  policy = data.aws_iam_policy_document.terraform_deployment.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "terraform_deployment" {
  role       = var.github_actions_role_name
  policy_arn = aws_iam_policy.terraform_deployment.arn
}