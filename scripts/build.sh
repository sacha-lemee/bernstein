#!/bin/bash
##
## EPITECH PROJECT, 2026
## Bernstein
## File description:
## build
##

# Stop on any error
set -euo pipefail

# Shared settings and helpers
source "$(dirname "$0")/common.sh"

# Reuse caller tag if set
TAG="${TAG:-$(image_tag)}"

# Build every service image
for service in $SERVICES; do
    echo "Building $(image_repo "$service"):$TAG"
    docker build --platform linux/amd64 \
        -t "$(image_repo "$service"):$TAG" \
        "$ROOT/poll-application/$service"
done
