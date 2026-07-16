#!/bin/bash

helm repo update

cd ../addons/charts

echo "Installing argo-rollouts..."
version=$(yq e '.dependencies[].version' argo-rollouts/Chart.yaml)
helm upgrade --install --rollback-on-failure --create-namespace --namespace argo-rollouts --version $version -f argo-rollouts/wsl.yaml -f argo-rollouts/$STAGE.yaml argo-rollouts argo/argo-rollouts

echo "Installing alloy..."
version=$(yq e '.dependencies[].version' alloy/Chart.yaml)
helm upgrade --install --rollback-on-failure --create-namespace --namespace alloy --version $version -f alloy/wsl.yaml -f alloy/$STAGE.yaml alloy grafana/alloy

echo "Installing grafana..."
version=$(yq e '.dependencies[].version' grafana/Chart.yaml)
helm upgrade --install --rollback-on-failure --create-namespace --namespace grafana --version $version -f grafana/wsl.yaml -f grafana/$STAGE.yaml grafana grafana/grafana

echo "Installing loki..."
version=$(yq e '.dependencies[].version' loki/Chart.yaml)
helm upgrade --install --rollback-on-failure --create-namespace --namespace loki --version $version -f loki/wsl.yaml -f loki/$STAGE.yaml loki grafana/loki

echo "Installing metrics-server..."
version=$(yq e '.dependencies[].version' metrics-server/Chart.yaml)
helm upgrade --install --rollback-on-failure --create-namespace --namespace metrics-server --version $version -f metrics-server/wsl.yaml -f metrics-server/$STAGE.yaml metrics-server metrics-server/metrics-server

echo "Installing prometheus..."
version=$(yq e '.dependencies[].version' prometheus/Chart.yaml)
helm upgrade --install --rollback-on-failure --create-namespace --namespace prometheus --version $version -f prometheus/wsl.yaml -f prometheus/$STAGE.yaml prometheus prometheus-community/prometheus

echo "Installing cnpg..."
version=$(yq e '.dependencies[].version' cnpg/Chart.yaml)
helm upgrade --install --rollback-on-failure --create-namespace --namespace cnpg --version $version -f cnpg/wsl.yaml -f cnpg/$STAGE.yaml cnpg cnpg/cloudnative-pg

echo "Installing ingress-haproxy..."
version=$(yq e '.dependencies[].version' ingress-haproxy/Chart.yaml)
helm upgrade --install --rollback-on-failure --create-namespace --namespace ingress-haproxy --version $version -f ingress-haproxy/wsl.yaml -f ingress-haproxy/$STAGE.yaml ingress-haproxy haproxy/kubernetes-ingress

if [ $PAT ]; then
  cd ..

  echo "Installing gha-runner..."
  helm upgrade --install --rollback-on-failure \
    --create-namespace \
    --namespace gha-runner \
    --set image.tag="$(grep 'ENV VERSION=' "custom/gha-runner/Dockerfile" | cut -d'=' -f2)" \
	  --set env[1].value=$PAT \
    -f ../.helm-tmpl/values.yaml -f custom/gha-runner/.helm/values.yaml -f custom/gha-runner/.helm/$STAGE/values.yaml \
    gha-runner ../.helm-tmpl
fi
