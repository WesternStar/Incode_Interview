# TODO

## 2026-07-02 — Modularize k8s/ components

Mirror the `aws_infra/modules/{vpc,dns,ecr,eks,rds}` pattern for the `k8s/`
root config:

- [x] `app` module — wraps `k8s/app.tf` (Deployment, Service, Ingress) with
      variables for namespace, replica count, image, subdomain, etc.
- [x] `monitoring` module — consolidates `k8s/monitoring.tf` and `k8s/yace.tf`
      into a single module, since YACE is monitoring infrastructure (it just
      bridges CloudWatch metrics into the same Prometheus this module already
      deploys) rather than a standalone component.
