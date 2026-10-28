#!/bin/bash
##
## EPITECH PROJECT, 2026
## Bernstein
## File description:
## aks
##

# Stop on any error
set -euo pipefail

# Overridable cluster names
RG="${RG:-bernstein-rg}"
AKS="${AKS:-bernstein-aks}"

# Print usage and exit
usage() {
    echo "Usage: $0 <start|stop|status>" >&2
    exit 1
}

# Require az and login
check_login() {
    if ! command -v az >/dev/null; then
        echo "Azure CLI not found. Install az first." >&2
        exit 1
    fi
    if ! az account show >/dev/null 2>&1; then
        echo "Not logged in to Azure. Run: az login" >&2
        exit 1
    fi
}

# Running or Stopped
power_state() {
    az aks show -g "$RG" -n "$AKS" --query powerState.code -o tsv
}

# Wait for pending operation
wait_idle() {
    az aks wait -g "$RG" -n "$AKS" --updated --timeout 900
}

# Wait for API server
wait_api() {
    local attempt
    for attempt in $(seq 1 30); do
        if kubectl get nodes --request-timeout=5s 2>/dev/null; then
            return
        fi
        echo "Waiting for API server ($attempt/30)"
        sleep 10
    done
    echo "API server unreachable after 5 minutes" >&2
    exit 1
}

# Start cluster, configure kubectl
start() {
    wait_idle
    if [ "$(power_state)" = "Running" ]; then
        echo "$AKS is already running"
    else
        az aks start -g "$RG" -n "$AKS"
    fi
    az aks get-credentials -g "$RG" -n "$AKS" --overwrite-existing
    wait_api
}

# Stop cluster, stop billing
stop() {
    wait_idle
    if [ "$(power_state)" = "Stopped" ]; then
        echo "$AKS is already stopped"
        return
    fi
    az aks stop -g "$RG" -n "$AKS"
}

# Show power and nodes
status() {
    az aks show -g "$RG" -n "$AKS" \
        --query "{power:powerState.code, state:provisioningState, nodes:agentPoolProfiles[0].count}" \
        -o table
}

# Exactly one argument
[ $# -eq 1 ] || usage
check_login

# Dispatch the subcommand
case "$1" in
    start) start ;;
    stop) stop ;;
    status) status ;;
    *) usage ;;
esac
