# Contributing to BERNSTEIN

BERNSTEIN was built by a fixed team during the Epitech curriculum. Issues and pull requests are welcome.

## Project layout

Kubernetes manifests are in `manifest/` with one overlay per target in `overlays/` (Minikube, AKS). The Bash scripts that build, push and deploy are in `scripts/`, the application sources in `poll-application/`. See the [README](README.md) to build and run it.

## Workflow

1. Open an issue describing the bug or the change.
2. Create a branch from `main`: `feat/<topic>`, `fix/<topic>` or `docs/<topic>`.
3. Commit with the convention of the history: `Type: summary`, e.g. `Feat: add PodDisruptionBudgets for poll and result`.
4. Open a pull request into `main` with a short list of the changes and `Closes #<issue>`.

## Code style

- Every resource gets requests and limits.
- Scripts start with `set -euo pipefail` and pass `shellcheck`.
- Check both overlays render with `kubectl kustomize overlays/minikube` and `kubectl kustomize overlays/aks`.

## Secrets

Never commit `.env`. Passwords go in `.env`, from `.env.example`, and reach the cluster as a Kubernetes Secret.

## Code of conduct

By contributing you agree to follow the [code of conduct](CODE_OF_CONDUCT.md).
