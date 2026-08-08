cd addons/charts

echo "Installing argo-cd..."
version=$(yq e '.dependencies[].version' argo-cd/Chart.yaml)
helm upgrade --install --rollback-on-failure --force-conflicts --create-namespace --namespace argo-cd --version $version --values argo-cd/values.yaml argo-cd argo/argo-cd

echo "Installing gha-runner..."
cd ..
helm upgrade --install --rollback-on-failure \
  --create-namespace \
  --namespace gha-runner \
  --force-conflicts \
  --set image.tag="$(grep 'ENV VERSION=' "custom/gha-runner/Dockerfile" | cut -d'=' -f2)" \
	--set env[1].value=$PAT \
  -f ${GITHUB_WORKSPACE}/.helm-tmpl/values.yaml -f custom/gha-runner/.helm/values.yaml -f custom/gha-runner/.helm/wsl/values.yaml \
  gha-runner ${GITHUB_WORKSPACE}/.helm-tmpl