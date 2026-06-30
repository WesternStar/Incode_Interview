locals {
  oidc_issuer = module.eks.cluster_oidc_issuer_url
  oidc_arn    = module.eks.oidc_provider_arn
}

# ---------------------------------------------------------------------------
# IAM role for the AWS Load Balancer Controller
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "lbc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(local.oidc_issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(local.oidc_issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lbc" {
  name               = "${var.project_name}-aws-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.lbc_assume_role.json

  tags = { Name = "${var.project_name}-aws-lb-controller" }
}

resource "aws_iam_policy" "lbc" {
  name   = "${var.project_name}-aws-lb-controller"
  policy = file("${path.module}/policies/aws-load-balancer-controller.json")
}

resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}

# ---------------------------------------------------------------------------
# IAM role for external-dns
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "external_dns_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(local.oidc_issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:external-dns"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(local.oidc_issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.project_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role.json

  tags = { Name = "${var.project_name}-external-dns" }
}

resource "aws_iam_policy" "external_dns" {
  name   = "${var.project_name}-external-dns"
  policy = file("${path.module}/policies/external-dns.json")
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}
