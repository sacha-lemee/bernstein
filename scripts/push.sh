#!/bin/bash
##
## EPITECH PROJECT, 2026
## Bernstein
## File description:
## push
##

# Stop on any error
set -euo pipefail

# Shared settings and helpers
source "$(dirname "$0")/common.sh"

# Reuse caller tag if set
TAG="${TAG:-$(image_tag)}"

# Nothing to push locally
if [ -z "$REGISTRY" ]; then
    echo "REGISTRY is empty, nothing to push" >&2
    exit 1
fi

# Log in with Azure account
az acr login -n "${REGISTRY%%.*}"

# Push every service image
for service in $SERVICES; do
    docker push "$(image_repo "$service"):$TAG"
done
