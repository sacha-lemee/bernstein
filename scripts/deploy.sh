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
SKIP_BUILD="${SKIP_BUILD:-}"
YES="${YES:-}"

# Temporary overlay inside repo
WORK_DIR="$(mktemp -d "$ROOT/.deploy.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

# Print usage and exit
usage() {
    echo "Usage: [SKIP_BUILD=1 TAG=<tag>] [YES=1] $0 <minikube|aks>" >&2
    exit 1
}

# Print error and exit
fail() {
    echo "Error: $*" >&2
    exit 1
}

# Hint and build tool per target
case "$TARGET" in
    minikube)
        START_HINT="Run: minikube start"
        BUILD_TOOL=minikube
        ;;
    aks)
        START_HINT="Check the kubeconfig and that the cluster is running"
        BUILD_TOOL=az
        ;;
    *) usage ;;
esac

# Build needs local tools
if [ "$SKIP_BUILD" = 1 ]; then
    TOOLS="kubectl"
else
    TOOLS="kubectl docker git $BUILD_TOOL"
fi

# Local images on Minikube
if [ "$TARGET" = minikube ] && [ "$SKIP_BUILD" != 1 ]; then
    REGISTRY=""
fi

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

# Given tag or computed one
resolve_tag() {
    if [ "$SKIP_BUILD" = 1 ]; then
        [ -n "${TAG:-}" ] || fail "SKIP_BUILD=1 requires TAG=<tag>"
    else
        TAG="${TAG:-$(image_tag)}"
    fi
    echo "Image tag: $TAG"
}

# Refuse the wrong cluster
check_context() {
    local current answer
    current="$(kubectl config current-context 2>/dev/null || true)"
    [ -n "$current" ] || fail "no kubectl context set"
    if [ "$TARGET" = minikube ] && [ "$current" != minikube ]; then
        fail "kubectl context is '$current', expected 'minikube'. Run: kubectl config use-context minikube"
    fi
    kubectl get nodes --request-timeout=10s >/dev/null 2>&1 \
        || fail "cluster unreachable. $START_HINT"
    if [ "$TARGET" = aks ] && [ "$YES" != 1 ]; then
        read -r -p "Deploy to context '$current'? [y/N] " answer || answer=""
        case "$answer" in
            y|Y) ;;
            *) fail "aborted. Set YES=1 to skip this prompt" ;;
        esac
    fi
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

# Build then push or load
ship_images() {
    local service
    export REGISTRY TAG
    "$ROOT/scripts/build.sh"
    if [ "$TARGET" = aks ]; then
        "$ROOT/scripts/push.sh"
    else
        for service in $SERVICES; do
            minikube image load "$(image_repo "$service"):$TAG"
        done
    fi
}

# Overlay plus image tags
apply_manifests() {
    local service
    {
        echo "apiVersion: kustomize.config.k8s.io/v1beta1"
        echo "kind: Kustomization"
        echo "resources:"
        echo "  - ../overlays/$TARGET"
        echo "images:"
        for service in $SERVICES; do
            echo "  - name: $service"
            echo "    newName: $(image_repo "$service")"
            echo "    newTag: \"$TAG\""
        done
    } > "$WORK_DIR/kustomization.yaml"
    kubectl apply -k "$WORK_DIR"
}

# Wait for every workload
wait_rollouts() {
    local workload
    for workload in $(kubectl get deployments,statefulsets -n "$NAMESPACE" -o name); do
        kubectl rollout status "$workload" -n "$NAMESPACE" --timeout=300s
    done
}

# Print public Service IPs
show_endpoints() {
    local query endpoints attempt
    query='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.name}{"\t"}{.status.loadBalancer.ingress[0].ip}{"\n"}{end}'
    for attempt in $(seq 1 24); do
        endpoints="$(kubectl get services -n "$NAMESPACE" -o jsonpath="$query")"
        if [ -z "$endpoints" ]; then
            echo "No LoadBalancer Service deployed yet"
            return
        fi
        if [ "$TARGET" = minikube ] \
            || ! echo "$endpoints" | awk -F'\t' '$2 == "" { p = 1 } END { exit !p }'; then
            break
        fi
        echo "Waiting for public IPs ($attempt/24)"
        sleep 5
    done
    echo "$endpoints" | awk -F'\t' '{ printf "%-8s http://%s\n", $1, ($2 == "" ? "<pending>" : $2) }'
    if [ "$TARGET" = minikube ]; then
        echo "Run 'minikube tunnel' in another terminal to get the IPs"
    fi
}

check_tools
check_env
resolve_tag
check_context
apply_secret

# Registry images are prebuilt
if [ "$SKIP_BUILD" != 1 ]; then
    ship_images
fi
apply_manifests
wait_rollouts
show_endpoints
