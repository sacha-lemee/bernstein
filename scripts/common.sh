#!/bin/bash
##
## EPITECH PROJECT, 2026
## Bernstein
## File description:
## common
##

# Repository root path
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Services built from source
SERVICES="poll worker result"

# Empty registry means local
REGISTRY="${REGISTRY-bernsteineon.azurecr.io}"

# Unique tag per source
image_tag() {
    local tag
    tag="$(git -C "$ROOT" rev-parse --short HEAD)"
    if [ -n "$(git -C "$ROOT" status --porcelain -- poll-application)" ]; then
        tag="$tag-dirty-$({
            git -C "$ROOT" diff HEAD -- poll-application
            git -C "$ROOT" ls-files -o --exclude-standard -z -- poll-application \
                | (cd "$ROOT" && xargs -0 -r sha1sum)
        } | sha1sum | cut -c1-7)"
    fi
    echo "$tag"
}

# Image name without tag
image_repo() {
    echo "${REGISTRY:+$REGISTRY/}$1"
}
