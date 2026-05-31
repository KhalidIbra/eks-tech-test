#!/usr/bin/env bash
#One-time cluster bootstrap after terraform apply
set -euo pipefail

ARGOCD_VERSION="${ARGOCD_VERSION:-v2.10.7}"
REGION="eu-west-2"
CLUSTER_NAME="$(terraform -chdir=terraform/environments/dev output -raw cluster_name)"

echo "Configuring kubectl for cluster ${CLUSTER_NAME}..."
aws eks update-kubeconfig --region "${REGION}" --name "${CLUSTER_NAME}"

echo "Installing ArgoCD ${ARGOCD_VERSION}..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

echo "Waiting for ArgoCD to be ready..."
kubectl -n argocd wait --for=condition=available --timeout=300s deployment/argocd-server

echo "Creating webserver namespace and DB credentials Secret..."
SECRET_ARN="$(terraform -chdir=terraform/environments/dev output -raw rds_credentials_secret_arn)"
DB_HOST="$(terraform -chdir=terraform/environments/dev output -raw rds_endpoint_address)"
DB_PORT="$(terraform -chdir=terraform/environments/dev output -raw rds_port)"
DB_NAME="$(terraform -chdir=terraform/environments/dev output -raw rds_db_name)"

CREDS_JSON="$(aws secretsmanager get-secret-value \
  --secret-id "${SECRET_ARN}" \
  --region "${REGION}" \
  --query SecretString --output text)"
DB_USER="$(echo "${CREDS_JSON}" | jq -r .username)"
DB_PASSWORD="$(echo "${CREDS_JSON}" | jq -r .password)"

kubectl create namespace webserver --dry-run=client -o yaml | kubectl apply -f -
kubectl -n webserver create secret generic webserver-db-credentials \
  --from-literal=DB_HOST="${DB_HOST}" \
  --from-literal=DB_PORT="${DB_PORT}" \
  --from-literal=DB_USER="${DB_USER}" \
  --from-literal=DB_PASSWORD="${DB_PASSWORD}" \
  --from-literal=DB_NAME="${DB_NAME}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Applying root Application..."
kubectl apply -f argocd/bootstrap.yaml

echo "Done. ArgoCD will now sync everything from Git."