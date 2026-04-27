#!/bin/bash
set -e

if [ -z "$REPO" ] || [ -z "$PAT" ]; then
  echo "REPO and PAT environment variables must be set"
  exit 1
fi

RESPONSE=$(curl -X POST \
  -H "Authorization: token $PAT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$REPO/actions/runners/registration-token)

RUNNER_TOKEN=$(echo $RESPONSE | jq '.["token"]' | tr -d '"')

./config.sh --unattended \
  --url "https://github.com/$REPO" \
  --token "$RUNNER_TOKEN" \
  --name "${RUNNER_NAME:-$(hostname)}" \
  --work "_work" \
  --replace

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add haproxy https://haproxytech.github.io/helm-charts
helm repo update

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token "$RUNNER_TOKEN"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh