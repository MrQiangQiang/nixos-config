#!/usr/bin/env bash

set -euo pipefail

CONTAINER_NAME="trae-env"
IMAGE="docker.io/library/ubuntu:24.04"
REAL_SETUP_SCRIPT="${HOME}/nixos-config/scripts/trae-container-setup.sh"

echo "=> [Host] Checking Distrobox container status..."
if ! podman container exists "$CONTAINER_NAME" 2>/dev/null && ! docker container exists "$CONTAINER_NAME" 2>/dev/null; then
  if ! distrobox list --no-color 2>/dev/null | grep -qw "$CONTAINER_NAME"; then
    echo "=> [Host] Container not found. Creating a clean Ubuntu environment.."
    distrobox create --name "$CONTAINER_NAME" --image "$IMAGE" --yes \
      --additional-flags "--dns 223.5.5.5 --dns 8.8.8.8"
  fi
fi

if [ ! -f "$REAL_SETUP_SCRIPT" ]; then
  echo "================================================================="
  echo "=> [Host Error ] Deployment interrupted: Internal setup script not found!"
  echo "=> Expected path: $REAL_SETUP_SCRIPT"
  echo "=> Please ensure your nixos-config repo is under your $HOME directory."
  echo "================================================================="
  exit 1
fi

echo "=> [Host] Entering container to inject the automated setup script.."

EXIT_CODE=0
# shellcheck disable=SC2154
distrobox enter "$CONTAINER_NAME" \
  --env http_proxy="{$http_proxy:-}" \
  --env https_proxy="{$https_proxy:-}" \
  --env all_proxy="{$all_proxy:-}" \
  --env no_proxy="{$no_proxy:-}" \
  -- bash "$REAL_SETUP_SCRIPT" || EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "================================================================="
  echo "=> [Host] Congratulations! Trae IDE is now ready for your River desktop!"
  echo "================================================================="
else
  echo "================================================================="
  echo "=> [Host] Container setup script exited with error code: $EXIT_CODE"
  echo "=> Please chech the English log output above to diagnose network/proxy issues"
  echo "================================================================="
  exit "$EXIT_CODE"
fi
