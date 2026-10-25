#!/bin/bash
##
## EPITECH PROJECT, 2026
## Bernstein
## File description:
## deploy
##

# Stop on any error
set -euo pipefail

# Shared settings and helpers
source "$(dirname "$0")/common.sh"

NAMESPACE=poll-app
ENV_FILE="${ENV_FILE:-$ROOT/.env}"
TARGET="${1:-}"

# Print usage and exit
usage() {
    echo "Usage: $0 <minikube|aks>" >&2
    exit 1
}

# Print error and exit
fail() {
    echo "Error: $*" >&2
    exit 1
}

# Context and tools per target
case "$TARGET" in
    minikube)
        CONTEXT=minikube
        START_HINT="minikube start"
        TOOLS="kubectl minikube"
        ;;
    aks)
        CONTEXT="${AKS:-bernstein-aks}"
        START_HINT="scripts/aks.sh start"
        TOOLS="kubectl az"
        ;;
    *) usage ;;
esac

# Required tools are installed
check_tools() {
    local tool
    for tool in $TOOLS; do
        command -v "$tool" >/dev/null || fail "$tool is not installed"
    done
}

# Both secrets are set
check_env() {
    local key
    [ -f "$ENV_FILE" ] || fail "$ENV_FILE not found. Run: cp .env.example .env"
    for key in POSTGRES_PASSWORD REDIS_PASSWORD; do
        grep -qE "^$key=.+" "$ENV_FILE" || fail "$key is empty in $ENV_FILE"
    done
}

# Refuse the wrong cluster
check_context() {
    local current
    current="$(kubectl config current-context 2>/dev/null || true)"
    if [ "$current" != "$CONTEXT" ]; then
        fail "kubectl context is '$current', expected '$CONTEXT'. Run: kubectl config use-context $CONTEXT"
    fi
    kubectl get nodes --request-timeout=10s >/dev/null 2>&1 \
        || fail "cluster unreachable. Run: $START_HINT"
}

# Namespace then Secret
apply_secret() {
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        kubectl create -f "$ROOT/manifest/namespaces/poll-app.yaml" --save-config
    fi
    kubectl create secret generic poll-secrets -n "$NAMESPACE" \
        --from-env-file="$ENV_FILE" --dry-run=client -o yaml \
        | kubectl apply -f -
}

# Wait for every workload
wait_rollouts() {
    local workload
    for workload in $(kubectl get deployments,statefulsets -n "$NAMESPACE" -o name); do
        kubectl rollout status "$workload" -n "$NAMESPACE" --timeout=300s
    done
}

check_tools
check_env
check_context
apply_secret
kubectl apply -k "$ROOT/overlays/$TARGET"
wait_rollouts
