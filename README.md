# AWS Demo Stack: VPC + EKS + RDS + Demo App

Two independent Terraform configs, applied in order:

1. **[`aws_infra/`](aws_infra)** — AWS-only. VPC (2 AZs, public/private subnets,
   single NAT gateway), EKS cluster with one managed node group (`t3.small`,
   1-3 nodes, on-demand), a single-AZ `db.t3.micro` RDS Postgres instance, a
   Route 53 hosted zone, an ACM wildcard certificate, and IRSA roles for the
   in-cluster controllers. Uses only the `aws` and `random` providers.
2. **[`k8s/`](k8s)** — Kubernetes-only. Reads `aws_infra/`'s outputs via
   `terraform_remote_state`, then installs the AWS Load Balancer Controller
   and external-dns via Helm, creates the app Deployment + ClusterIP Service +
   ALB Ingress (HTTPS, HTTP→HTTPS redirect), and lets external-dns
   automatically create the Route 53 A alias record from the Ingress annotation.
   Uses only the `kubernetes` and `helm` providers — auth is done via the
   `aws eks get-token` CLI exec plugin.

Keeping these separate avoids the classic problem of a single state mixing
the AWS and Kubernetes providers, where the Kubernetes provider can't be
configured until the cluster exists, and a `destroy`/`taint` on one side can
disrupt the other.

## Prerequisites

- `terraform` >= 1.5
- `aws` CLI configured with credentials for your target account
- `kubectl` and `helm` (for manual inspection; Terraform drives them during apply)
- A domain name you control, registered at any registrar

## Usage

### Step 1 — Provision AWS infrastructure

```bash
cd aws_infra
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — at minimum set domain_name = "yourdomain.com"
terraform init
terraform plan
terraform apply
```

### Step 2 — Delegate your domain to Route 53 ⚠️

This is a **manual step** that must happen before `k8s/` apply, because ACM
certificate validation and external-dns both depend on Route 53 being
authoritative for your domain. Without it, cert validation will hang and DNS
records will never resolve.

**Get the name servers Terraform just created:**

```bash
terraform output route53_name_servers
```

This prints four NS values, e.g.:
```
[
  "ns-123.awsdns-45.com",
  "ns-678.awsdns-90.net",
  "ns-111.awsdns-22.org",
  "ns-999.awsdns-55.co.uk",
]
```

**Go to your domain registrar** (GoDaddy, Namecheap, Google Domains, etc.) and
replace the existing NS records for your domain with these four values. The
exact UI varies by registrar but the field is usually called
"Nameservers" or "DNS" under your domain's settings.

**Wait for NS propagation** before continuing — this typically takes a few
minutes but can take up to 48 hours depending on your registrar's TTL.
You can check propagation with:

```bash
dig NS yourdomain.com +short
# Should return the four awsdns-* values above
```

**Verify the ACM certificate was issued:**

```bash
aws acm describe-certificate \
  --certificate-arn $(cd aws_infra && terraform output -raw acm_certificate_arn) \
  --query "Certificate.Status"
# Should return "ISSUED" — if it says "PENDING_VALIDATION", NS delegation
# hasn't propagated yet; wait and retry.
```

### Step 3 — Configure kubectl

```bash
$(cd aws_infra && terraform output -raw configure_kubectl)
```

### Step 4 — Deploy the Kubernetes workload

```bash
cd ../k8s
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set domain_name and app_subdomain to match aws_infra
terraform init
terraform plan
terraform apply
```

After apply, external-dns will detect the Ingress annotation and create the
Route 53 A alias record within ~30 seconds. Then verify end-to-end:

```bash
# Check controllers are running
kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl -n kube-system get pods -l app.kubernetes.io/name=external-dns

# Check the ALB was provisioned
kubectl get ingress demo-app

# Hit the app (replace with your actual subdomain)
curl https://music.yourdomain.com
```

## Monitoring (Prometheus + Grafana)

`k8s/monitoring.tf` installs `kube-prometheus-stack` (Prometheus + Grafana),
scraping the demo app's `/metrics` endpoint automatically. Grafana is exposed
the same way as the app, at `https://grafana.yourdomain.com` (from the
`grafana_subdomain` var).

```bash
# Grafana URL
cd k8s && terraform output grafana_url

# Grafana admin password (username: admin)
terraform output -raw grafana_admin_password

# Or read the password straight from the cluster instead of Terraform state:
kubectl -n monitoring get secret grafana-admin-credentials \
  -o jsonpath='{.data.admin-password}' | base64 -d
```

## Cost-saving choices

- Single NAT gateway instead of one per AZ.
- Small `t3.small` nodes, 1-3 node autoscaling range, on-demand (swap
  `capacity_type` to `SPOT` in `aws_infra/eks.tf` for further savings if
  interruption tolerance is acceptable).
- Single-AZ `db.t3.micro` RDS instance, 1-day backup retention, no final
  snapshot on destroy.

## Teardown

Tear down in reverse order — `k8s/` first so the ALB and DNS records are
cleaned up before the VPC/subnets they depend on are destroyed:

```bash
cd k8s && terraform destroy
# Wait ~2 minutes for the ALB to be fully deleted by the controller,
# then destroy the AWS infrastructure:
cd ../aws_infra && terraform destroy
```

> **Note:** The ALB is managed by the AWS Load Balancer Controller inside
> Kubernetes, not a Terraform resource directly. `terraform destroy` in `k8s/`
> deletes the Ingress, which triggers the controller to delete the ALB. If you
> destroy `aws_infra/` before the ALB is gone, the VPC deletion will fail
> because the ALB's ENIs are still attached to the subnets. Allow a minute or
> two after `k8s/ terraform destroy` completes before running the infra destroy.
