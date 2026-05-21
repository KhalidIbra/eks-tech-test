#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-eu-west-2}"
CLUSTER_NAME="${CLUSTER_NAME:-boba-tech-test-dev-cluster}"
DOMAIN="${DOMAIN:-hello.kihellowebserver.co.uk}"

cyan()   { printf "\033[36m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
red()    { printf "\033[31m%s\033[0m\n" "$*"; }

cyan "==> Pre-flight: verifying cluster access"
if ! kubectl cluster-info --request-timeout=5s &>/dev/null; then
  yellow "kubectl can't reach the cluster. Either it's already gone, or your kubeconfig is stale."
  yellow "Skipping in-cluster steps and going straight to Terraform destroy."
  SKIP_CLUSTER=true
else
  SKIP_CLUSTER=false
fi

if [ "$SKIP_CLUSTER" = false ]; then
  cyan "==> Step 1: Disable ArgoCD self-heal so deletions stick"
  kubectl -n argocd patch application root --type merge \
    -p '{"spec":{"syncPolicy":null}}' 2>/dev/null || true

  cyan "==> Step 2: Delete the root Application (cascades to all children)"
  # Clear finalizer first so the delete completes
  kubectl -n argocd patch application root --type merge \
    -p '{"metadata":{"finalizers":null}}' 2>/dev/null || true
  kubectl -n argocd delete application root --ignore-not-found

  # Clear finalizers on all child apps too, in case any are stuck
  for app in $(kubectl -n argocd get applications -o name 2>/dev/null); do
    kubectl -n argocd patch "$app" --type merge \
      -p '{"metadata":{"finalizers":null}}' 2>/dev/null || true
  done
  kubectl -n argocd delete applications --all --ignore-not-found

  cyan "==> Step 3: Wait for the ALB to be deleted by the LBC"
  # The webserver Ingress disappearing causes the LBC to delete the ALB.
  # This is asynchronous and we MUST wait, or Terraform will fail on VPC deletion.
  for i in {1..30}; do
    ALB_COUNT=$(aws elbv2 describe-load-balancers --region "$REGION" \
      --query "length(LoadBalancers[?contains(LoadBalancerName, 'k8s-webserve')])" \
      --output text 2>/dev/null || echo "0")
    if [ "$ALB_COUNT" = "0" ]; then
      cyan "    ALB confirmed deleted."
      break
    fi
    yellow "    Waiting for ALB cleanup... ($i/30, found $ALB_COUNT)"
    sleep 10
  done

  if [ "$ALB_COUNT" != "0" ]; then
    red "    ALB still present after 5 minutes. Continuing, but Terraform may fail."
    red "    Check: aws elbv2 describe-load-balancers --region $REGION"
  fi

  cyan "==> Step 4: Delete the manually-created webserver-db-credentials Secret"
  # Not strictly necessary (the namespace gets deleted with the cluster)
  # but tidy.
  kubectl -n webserver delete secret webserver-db-credentials --ignore-not-found
fi

cyan "==> Step 5: Delete the Route53 A-record (created manually outside Terraform)"
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name=='${DOMAIN#hello.}.'].Id" \
  --output text 2>/dev/null | sed 's|/hostedzone/||')

if [ -n "$HOSTED_ZONE_ID" ]; then
  RECORD=$(aws route53 list-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --query "ResourceRecordSets[?Name=='${DOMAIN}.' && Type=='A']" \
    --output json 2>/dev/null)

  if [ "$(echo "$RECORD" | jq 'length')" -gt 0 ]; then
    echo "$RECORD" | jq --arg name "${DOMAIN}." '{
      Changes: [{
        Action: "DELETE",
        ResourceRecordSet: .[0]
      }]
    }' > /tmp/r53-delete.json

    aws route53 change-resource-record-sets \
      --hosted-zone-id "$HOSTED_ZONE_ID" \
      --change-batch file:///tmp/r53-delete.json >/dev/null
    rm -f /tmp/r53-delete.json
    cyan "    Route53 record deleted."
  else
    yellow "    No Route53 A-record found for $DOMAIN, skipping."
  fi
else
  yellow "    Couldn't find hosted zone for ${DOMAIN#hello.}, skipping Route53 cleanup."
fi

cyan "==> Step 6: Terraform destroy"
cd terraform/environments/dev

# Required for destroy: RDS deletion protection must be off and final snapshot
# must be skippable. These should already match dev defaults but enforce
# explicitly here.
terraform apply -auto-approve \
  -var "rds_deletion_protection=false" \
  -var "rds_skip_final_snapshot=true" \
  -target=module.rds 2>/dev/null || true

terraform destroy -auto-approve

cyan "==> Done."
cyan "    To re-provision: terraform apply, then ./scripts/bootstrap.sh"