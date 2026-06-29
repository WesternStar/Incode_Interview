# AWS Demo Stack: VPC + EKS + RDS + Demo App

Two independent Terraform configs, applied in order:

1. **[`aws_infra/`](aws_infra)** — AWS-only. VPC (2 AZs, public/private subnets,
   single NAT gateway), EKS cluster with one managed node group (`t3.small`,
   1-3 nodes, on-demand), and a single-AZ `db.t3.micro` RDS Postgres instance
   reachable only from the EKS node security group on port 5432. Uses only
   the `aws` and `random` providers.
2. **[`k8s/`](k8s)** — Kubernetes-only. Reads `aws_infra/`'s outputs via
   `terraform_remote_state`, then creates a `db-credentials` Secret from the
   RDS connection info, a Deployment (2 replicas of `nginxdemos/hello` by
   default) wired up with those credentials as env vars, and a
   `LoadBalancer` Service (provisions an internet-facing AWS NLB). Uses only
   the `kubernetes` provider — auth is done via the `aws eks get-token` CLI
   exec plugin, so this config has no Terraform-level dependency on the AWS
   provider/credentials beyond having the `aws` CLI available on `$PATH`.

Keeping these separate avoids the classic problem of a single state mixing
the AWS and Kubernetes providers, where the Kubernetes provider can't be
configured until the cluster exists, and a `destroy`/`taint` on one side can
disrupt the other.

## Usage

```bash
# 1. Provision the AWS infrastructure
cd aws_infra
cp terraform.tfvars.example terraform.tfvars   # edit as needed
terraform init
terraform plan
terraform apply

# 2. Configure kubectl (optional, useful for manual checks)
$(terraform output -raw configure_kubectl)

# 3. Deploy the Kubernetes workload
cd ../k8s
cp terraform.tfvars.example terraform.tfvars   # edit as needed
terraform init
terraform plan
terraform apply
```

After the `k8s/` apply:

```bash
kubectl get pods
kubectl get svc demo-app   # wait for EXTERNAL-IP / hostname to populate

curl http://$(terraform output -raw demo_app_service_hostname)
```

## Cost-saving choices

- Single NAT gateway instead of one per AZ.
- Small `t3.small` nodes, 1-3 node autoscaling range, on-demand (swap
  `capacity_type` to `SPOT` in `aws_infra/eks.tf` for further savings if
  interruption tolerance is acceptable).
- Single-AZ `db.t3.micro` RDS instance, 1-day backup retention, no final
  snapshot on destroy.

## Teardown

Tear down in the reverse order, since `aws_infra/`'s EKS/VPC resources back the
`k8s/` workload:

```bash
cd k8s && terraform destroy
cd ../aws_infra && terraform destroy
```

Note: the LoadBalancer Service's NLB is managed by the Kubernetes/AWS cloud
controller, not a Terraform resource directly — `terraform destroy` in
`k8s/` deletes the Service, which triggers AWS to clean up the NLB, but
allow a minute or two for that to finish before destroying `aws_infra/`.
