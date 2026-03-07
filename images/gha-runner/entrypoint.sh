#!/bin/bash
set -e

if [ -z "$REPO_URL" ] || [ -z "$PAT" ]; then
  echo "REPO_URL and PAT environment variables must be set"
  exit 1
fi

REPO=$(echo "awk $REPO_URL" | awk '{split($2,a,"/"); print a[4]"/"a[5]}')

RESPONSE=$(curl -X POST \
  -H "Authorization: token $PAT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$REPO/actions/runners/registration-token)

RUNNER_TOKEN=$(echo $RESPONSE | jq '.["token"]' | tr -d '"')

./config.sh --unattended \
  --url "$REPO_URL" \
  --token "$RUNNER_TOKEN" \
  --name "${RUNNER_NAME:-$(hostname)}" \
  --work "_work" \
  --replace

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token "$RUNNER_TOKEN"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh
