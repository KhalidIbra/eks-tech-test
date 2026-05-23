# TODO

Improvements and additions I would make if given more time 

## Secret Management

Replace the manual `kubectl create secret` step with the External Secrets Operator.I intended to use this in the beginning, however due to frequent errors and time-constraints, I dropped it.


## Multi-Environment

Currently only `dev` which works but would add `staging` and `prod` in a real scenario:

- Introduce Terragrunt to keep environment configs DRY. Each leaf `terragrunt.hcl` references the shared modules with environment-specific inputs.
- Split the GitOps repo or use ArgoCD `ApplicationSet` to manage per-environment overlays in `k8s/apps/webserver/overlays/{dev,staging,prod}/`.
- Promote releases by updating the image tag in the next environment's overlay rather than rebuilding.

## Network Hardening

- Add `NetworkPolicy` resources to constrain pod-to-pod traffic. 
- Enable VPC Flow Logs to CloudWatch.
- Add a WAF in front of the ALB for managed rule sets.


## Supply Chain

- Pin every GitHub Action to a commit SHA, not a tag to protect against tag mutation.
- Add tfsec or Checkov to the CI pipeline as a Terraform pre-merge check.


## Reliability

- RDS read replicas in the second AZ for read-heavy traffic; currently Multi-AZ standby is failover-only.
- Encrypt RDS with a customer-managed KMS key with rotation enabled, not the AWS-managed default.
- Add a `HorizontalPodAutoscaler` for the webserver Deployment (CPU-based to start, metrics-server-based custom metrics later).

## Deployments

- Enable canary or blue/green deploys with automated rollback on metric thresholds using ArgoCD.

## CI/CD

- Branch protection on `main` with required status checks and required reviews.
- Replace the default `GITHUB_TOKEN` for the bot commit with a GitHub App token that has commit-signing.
- Notify deploys to chosen notification channel, e.g Slack, from the GitOps workflow.

## Operational

- A `bootstrap/` Terraform config with local state, creating the S3 backend bucket, DynamoDB lock table, GitHub OIDC provider, and CI IAM role. Currently created in the AWS console as a one-time setup, which is fast but not reproducible.
- A separate infrastructure pipeline which prompts Terraform to provision/update resources.
- Runbooks for common incidents
- Disaster recovery plan and tested restore procedure for RDS snapshots.
- Cost monitoring: AWS Budgets with alerts defined