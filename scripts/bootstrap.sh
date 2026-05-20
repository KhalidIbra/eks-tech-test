#!/usr/bin/env bash
#One-time cluster bootstrap after terraform apply
set -euo pipefail

ARGOCD_VERSION="${ARGOCD_VERSION:-v2.10.7}"
REGION="$(terraform -chdir=terraform/environments/dev output -raw region)"
CLUSTER_NAME="$(terraform -chdir=terraform/environments/dev output -raw cluster_name)"

echo "Configuring kubectl for cluster ${CLUSTER_NAME}..."
aws eks update-kubeconfig --region "${REGION}" --name "${CLUSTER_NAME}"

echo "Installing ArgoCD ${ARGOCD_VERSION}..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

echo "Waiting for ArgoCD to be ready..."
kubectl -n argocd wait --for=condition=available --timeout=300s deployment/argocd-server

echo "Applying root Application..."
kubectl apply -f argocd/bootstrap.yml

echo "Done. ArgoCD will now sync everything from Git."