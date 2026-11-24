data "aws_iam_policy_document" "terraform_backend" {
  statement {
    sid = "ListTerraformState"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}"
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        var.terraform_state_key,
        "${var.terraform_state_key}.tflock"
      ]
    }
  }

  statement {
    sid = "ReadWriteTerraformState"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}/${var.terraform_state_key}"
    ]
  }

  statement {
    sid = "ManageTerraformStateLock"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}/${var.terraform_state_key}.tflock"
    ]
  }
}

resource "aws_iam_policy" "terraform_backend" {
  name        = "${var.github_actions_role_name}-terraform-backend"
  description = "Terraform backend access for GitHub Actions"

  policy = data.aws_iam_policy_document.terraform_backend.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "terraform_backend" {
  role       = var.github_actions_role_name
  policy_arn = aws_iam_policy.terraform_backend.arn
}