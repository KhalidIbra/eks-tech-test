# boba-tech-test

A highly available webserver on EKS with a MySQL backend, deployed via GitOps. Infrastructure is provisioned with Terraform; cluster state is managed by ArgoCD; application builds and manifest updates flow through GitHub Actions.

## Architecture

<img width="812" height="850" alt="image" src="https://github.com/user-attachments/assets/ab683f18-b811-4136-8ce0-d32229187506" />



## Repository Layout

```
.
├── terraform/
│   ├── environments/dev/      
│   └── modules/
│       ├── networking/        
│       ├── eks/               
│       ├── rds/                
│       ├── ecr/               
│       └── dns-certs/         
├── k8s/
│   └── apps/                  

├── argocd/
│   ├── root-app.yaml         
│   └── apps/
│       ├── aws-load-balancer-controller.yaml
│       ├── monitoring.yaml     
│       └── webserver.yaml
├── app/                        
├── .github/workflows/
│   ├── build.yml               
│   └── gitops-deploy.yml       
└── scripts/
    └── bootstrap.sh            
    └── teardown.sh            

```

## Deployment

Prerequisites: AWS credentials with sufficient privileges, a Route53 hosted zone for your domain, GitHub repo with OIDC role configured for ECR push.

```bash
# 1. Provision cloud infrastructure
cd terraform/environments/dev
terraform init
terraform apply

# 2. Bootstrap the cluster 
./scripts/bootstrap.sh

# 3. Create the DB credentials Secret 
kubectl create namespace webserver --dry-run=client -o yaml | kubectl apply -f -
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id devops-eks-demo-dev-db-credentials \
  --region eu-west-2 \
  --query SecretString --output text)
kubectl -n webserver create secret generic webserver-db-credentials \
  --from-literal=DB_HOST=$(echo "$SECRET_JSON" | jq -r .host) \
  --from-literal=DB_PORT=$(echo "$SECRET_JSON" | jq -r .port) \
  --from-literal=DB_USER=$(echo "$SECRET_JSON" | jq -r .username) \
  --from-literal=DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r .password) \
  --from-literal=DB_NAME=$(echo "$SECRET_JSON" | jq -r .dbname)

# 4. Once the ALB exists, create the Route53 A-record (alias to the ALB DNS name)
kubectl -n webserver get ingress webserver
# Use the ADDRESS column value to create a Route53 alias for hello.<your-domain>

# 5. Push an app change to trigger the first deploy
# CI builds, pushes, updates the Kustomization, ArgoCD syncs, the site comes up at:
# https://hello.kihellowebserver.co.uk
```

## GitOps Flow

The deploy pipeline never touches the cluster. Instead:

1. Developer pushes a change on `main`.
2. `build.yml` runs lint, tests, Trivy scan, then builds and pushes the image to ECR, tagged with the short commit SHA. Tags are immutable.
3. On success, `gitops-deploy.yml` runs `kustomize edit set image` against `k8s/apps/webserver/kustomization.yaml`, commits the change as the `github-actions[bot]` user with `[skip ci]` in the message, and pushes.
4. ArgoCD detects the manifest change within a minute and rolls the new image.

 `git log` shows an alternating pattern of developer `feat:` commits and bot `chore(deploy):` commits. Every deploy is a Git operation, traceable and reversible.

Rollback can easily be done through the ArgoCD UI

## Design Choices

**Terraform over Terragrunt.** I only have one environment to handle in this case and I am more familiar with Terraform modules, so this reduces complexity and time for me.


**ArgoCD over Flux.** Either works. ArgoCD's UI helps with the demo aspect of the test, and the "app of apps" pattern was a natural fit.


**Terraform stops at the cluster boundary.** Terraform provisions cloud resources and IAM roles. ArgoCD owns everything inside the cluster. The split keeps each tool focused on what it's actually good at.


**Manual DB credentials Secret.** A one-time `kubectl create secret` after Terraform apply. The production path (External Secrets Operator with IRSA reading directly from Secrets Manager) is documented in TODO.md and the IAM role is already provisioned.

## Security Considerations


**CI authentication.** GitHub Actions authenticates to AWS via OIDC federation. No long-lived access keys exist. The IAM role's trust policy restricts assumption to workflows in this specific repository using the `token.actions.githubusercontent.com:sub` condition. The permissions policy is scoped to the single ECR repository.

**Cluster authentication.** EKS access entries (not the legacy `aws-auth` ConfigMap) grant cluster-admin to the provisioning IAM role. RBAC inside the cluster handles per-service permissions.

**Pod-to-AWS authentication.** All AWS access from inside the cluster uses IRSA — IAM Roles for Service Accounts. The AWS Load Balancer Controller's ServiceAccount assumes a role with scoped permissions; the External Secrets role (provisioned but not currently used) does the same. No AWS credentials are mounted into containers.

**Network segmentation.** RDS lives in private subnets with a security group that only allows ingress from the EKS node security group on port 3306. The ALB is internet-facing; everything behind it is private. EKS nodes are in private subnets and reach the internet via NAT only.

**Data encryption.** RDS storage is encrypted at rest with AWS-managed KMS. ECR repositories use AES-256 encryption. ACM provides TLS in transit at the ALB; HTTP-to-HTTPS redirect is enforced.

**Secrets handling.** The RDS master password is generated by Terraform's `random_password` and stored in AWS Secrets Manager. It never appears in Terraform state outputs, never in Git, never in CI logs. The Kubernetes Secret is created manually from the Secrets Manager value at bootstrap. Rotation requires a manual refresh — see TODO.md. Grafana password is also generated via Helm chart and stored as a Kubernetes secret. It can be retrieved using:

kubectl -n monitoring get secret monitoring-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d

**Image security.** ECR repositories are configured with immutable tags so a pushed image can never be silently overwritten. Trivy scans every image in CI and fails the build on CRITICAL or HIGH severity findings. 

**Container hardening.** Pods run as non-root with read-only root filesystem, dropped capabilities, and `allowPrivilegeEscalation: false`. Resource requests and limits are set on every container.

**Public surface area.** Exactly one public endpoint: the ALB on HTTPS, serving a single hostname. EKS API endpoint is currently public but authentication-gated; production would restrict via `public_access_cidrs` to a VPN range.

## Service Validation



1. **Kubernetes probes.** Liveness and readiness probes hit `/health` on every pod. Failures restart the container or remove it from the Service endpoints.

2. **ALB target health.** The Application Load Balancer health-checks the same path. Unhealthy targets are removed from rotation; if all targets are unhealthy, the listener returns 503.

3. **External synthetic check.** The simplest version: `curl https://hello.<domain>/` from CI on a schedule. Production would use Route53 health checks or a CloudWatch Synthetics canary running every minute and alarming on failure.

4. **Metrics-based detection.** Prometheus (via kube-prometheus-stack) scrapes cluster components. A `ServiceMonitor` for the webserver plus a recording rule on HTTP 5xx rate would detect application-level failures the health probe doesn't catch.

## Monitoring

`kube-prometheus-stack` is deployed as an ArgoCD Application sourcing the upstream Helm chart. Grafana is exposed via port-forward (`kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80`). Default dashboards cover cluster, node, and pod metrics.


## Teardown


Run `./scripts/teardown.sh` from the repository root. This:

1. Disables ArgoCD self-heal so deletions persist.
2. Deletes ArgoCD Applications, which triggers the AWS Load Balancer Controller to delete the ALB.
3. Waits up to 5 minutes for AWS-side ALB cleanup to complete (this prevents `terraform destroy` from failing on VPC dependency violations).
4. Deletes the manually-created Route53 A-record.
5. Runs `terraform destroy`.

The script is idempotent and safe to re-run if any step fails. 

