#!/bin/bash
set -e

if [ -z "$REPO_URL" ] || [ -z "$RUNNER_TOKEN" ]; then
  echo "REPO_URL and RUNNER_TOKEN environment variables must be set"
  exit 1
fi

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
