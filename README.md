# DevOps - Orchestration - Bernstein

This is an **Epitech project** called Bernstein.

It's a four-week project from the fifth semester of the Epitech **DevOps - Orchestration module** (**G-DOP-500**).

## Project Overview

The goal of this project is to **set up a complete deployment process for a Poll application, from the source code to the Kubernetes cluster**.
(The web application is given by the school)

The languages used are **YAML for Kubernetes deployment** and **Bash to automate build, push and deployment**.

We've used **Docker** and **Azure**, to deploy the containers.

## Epitech Warning

**This is a warning to all epitech students:** 
- **We recall you that being a copycat at EPITECH will not bring you any good.**
- **Copying is totally banned at EPITECH and by not respecting this rule you can be scolded.**

## Prerequisites

- `kubectl` connected to a running cluster with a default StorageClass and LoadBalancer support (Minikube or AKS)
- Docker and the Azure CLI, only to build and push images

## Quick start

Deploy the published images on a local [Minikube](https://minikube.sigs.k8s.io/) cluster, no Azure account needed:

```sh
git clone git@github.com:sacha-lemee/bernstein.git
cd bernstein
cp .env.example .env    # set both passwords
minikube start
SKIP_BUILD=1 TAG=87b6fe1 ./scripts/deploy.sh minikube
minikube tunnel         # in another terminal, to get the public IPs of poll and result
```

To build the images yourself instead, drop `SKIP_BUILD=1 TAG=87b6fe1`: they are built locally and loaded into Minikube. For AKS, see [docs/deployment.md](docs/deployment.md).

## Deployment

Deployment of the Poll application on Azure Kubernetes Service.

```
poll --> redis --> worker --> postgres <-- result
```

| Service | Stack | Exposure |
|---|---|---|
| poll | Python / Flask | Public |
| result | Node.js / Socket.IO | Public |
| worker | Java | Internal |
| redis | Redis 8 | Internal |
| postgres | PostgreSQL 18 | Internal |

## Infrastructure

| Resource | Value |
|---|---|
| Region | `belgiumcentral` |
| Resource group | `bernstein-rg` |
| Cluster | `bernstein-aks` |
| Registry | `bernsteineon.azurecr.io` |
| Namespace | `poll-app` |

Provisioning steps and subscription constraints: [docs/azure-setup.md](docs/azure-setup.md).

## Secrets

Secrets are never committed. Copy the template and fill in the values:

```sh
cp .env.example .env
```

| Key | Used by |
|---|---|
| `POSTGRES_PASSWORD` | postgres worker result |
| `REDIS_PASSWORD` | redis poll worker |

Azure credentials are not stored in the repository. Authenticate with `az login`.

## Documentation

- **Deployment & Usage of the images**: [docs/deployment.md](docs/deployment.md)
- **Azure Setup & Infrastructure**: [docs/azure-setup.md](docs/azure-setup.md)

## Authors

| [<img src="https://avatars.githubusercontent.com/u/181952346?v=4?size=85" width=85><br><sub>Sacha Lemee</sub>](https://github.com/sacha-lemee) |
| :---: |
| [<img src="https://avatars.githubusercontent.com/u/181121247?v=4?size=85" width=85><br><sub>Quentin Dutournier-Ottenin</sub>](https://github.com/Patate-with-computer) |
