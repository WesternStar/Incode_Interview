data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# KMS key for RDS storage encryption
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "kms_rds" {
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "rds" {
  description             = "Encrypts the ${var.project_name} RDS instance's storage"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_rds.json

  tags = { Name = "${var.project_name}-rds" }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ---------------------------------------------------------------------------
# KMS key for EKS worker node EBS root volume encryption
# ---------------------------------------------------------------------------
# The autoscaling.amazonaws.com service-linked role isn't created until the
# first Auto Scaling Group is provisioned in the account. Our node group's
# ASG can't exist yet (it needs this KMS key first), so the role won't exist
# when the key policy below references it — create it explicitly to break
# the chicken-and-egg dependency.
resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}

data "aws_iam_policy_document" "kms_ebs" {
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # The node group's Auto Scaling group creates each node's encrypted root
  # volume on our behalf at launch time. Without this grant, EC2 Auto Scaling
  # can't use the key and instance launches fail with a client error, so
  # nodes never join the cluster.
  statement {
    sid    = "AllowAutoScalingToUseKeyForEBS"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKeyWithoutPlaintext",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_service_linked_role.autoscaling.arn]
    }
  }
}

resource "aws_kms_key" "ebs" {
  description             = "Encrypts ${var.project_name} EKS worker node EBS volumes"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_ebs.json

  tags = { Name = "${var.project_name}-ebs" }
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project_name}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}
