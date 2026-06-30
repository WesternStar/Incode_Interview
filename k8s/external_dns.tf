resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = "1.14.5"

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  # Scope external-dns to only manage records within this hosted zone.
  set {
    name  = "domainFilters[0]"
    value = var.domain_name
  }

  set {
    name  = "txtOwnerId"
    value = local.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = data.terraform_remote_state.infra.outputs.external_dns_role_arn
  }

  # Only manage records that external-dns itself creates — avoids touching
  # manually created records in the hosted zone (e.g. cert validation CNAMEs).
  set {
    name  = "policy"
    value = "sync"
  }

  depends_on = [helm_release.aws_load_balancer_controller]
}
