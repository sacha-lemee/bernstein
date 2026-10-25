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

# Start cluster, configure kubectl
start() {
    if [ "$(power_state)" = "Running" ]; then
        echo "$AKS is already running"
    else
        az aks start -g "$RG" -n "$AKS"
    fi
    az aks get-credentials -g "$RG" -n "$AKS" --overwrite-existing
    kubectl get nodes
}

# Stop cluster, stop billing
stop() {
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
