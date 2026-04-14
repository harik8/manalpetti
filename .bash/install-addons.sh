#!/bin/bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add haproxy https://haproxytech.github.io/helm-charts
helm repo update

cd ../addons/charts

echo "Installing alloy..."
helm upgrade --install --rollback-on-failure --create-namespace --namespace alloy --version 1.3.1 --values alloy/values.yaml alloy grafana/alloy

echo "Installing argo-rollouts..."
helm upgrade --install --rollback-on-failure --create-namespace --namespace argo-rollouts --version 2.39.6 --values argo-rollouts/values.yaml  argo-rollouts argo/argo-rollouts

echo "Installing grafana..."
helm upgrade --install --rollback-on-failure --create-namespace --namespace grafana --version 10.1.2 --values grafana/values.yaml grafana grafana/grafana

echo "Installing loki..."
helm upgrade --install --rollback-on-failure --create-namespace --namespace loki --version 6.43.0 --values loki/values.yaml loki grafana/loki

echo "Installing metrics-server..."
helm upgrade --install --rollback-on-failure --create-namespace --namespace metrics-server --version 3.12.2 --values metrics-server/values.yaml metrics-server metrics-server/metrics-server

echo "Installing prometheus..."
helm upgrade --install --rollback-on-failure --create-namespace --namespace prometheus --version 27.41.1 --values prometheus/values.yaml prometheus prometheus-community/prometheus

echo "Installing cnpg..."
helm upgrade --install --rollback-on-failure --create-namespace --namespace cnpg --version 0.27.1 --values cnpg/values.yaml cnpg cnpg/cloudnative-pg

echo "Installing ingress-haproxy..."
helm upgrade --install --rollback-on-failure --create-namespace --namespace ingress-haproxy --version 1.49.0 --values ingress-haproxy/values.yaml ingress-haproxy haproxy/kubernetes-ingress

if [ $PAT ]; then
  cd ..
  echo "Installing gha-runner..."
  helm upgrade --install --rollback-on-failure \
    --create-namespace \
    --namespace gha-runner \
    --set image.tag="$(grep 'ENV VERSION=' "custom/gha-runner/Dockerfile" | cut -d'=' -f2)" \
	  --set env[1].value=$PAT \
    -f .helm-tmpl/values.yaml -f custom/gha-runner/.helm/values.yaml -f custom/gha-runner/.helm/sandbox/values.yaml \
    gha-runner .helm-tmpl
fi
