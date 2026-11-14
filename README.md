# BERNSTEIN

### Development

By *Quentin Dutournier-Ottenin*(quentin.dutournier-ottenin@epitech.eu) & *Sacha Lemée*(sacha.lemee@epitech.eu).

## Objective

A four-week project of the Epitech **DevOps - Orchestration** module (G-DOP-500): **set up a complete deployment process for a poll application, from the source code to a Kubernetes cluster**. The web application is given by the school.

- **YAML** (Kustomize) for the Kubernetes resources, **Bash** to build, push and deploy
- **Docker** images hosted on **Azure Container Registry**, deployed on **Azure Kubernetes Service** or locally on **Minikube**

## Architecture

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

## Getting Started

### Prerequisites

This project requires:
- `kubectl` connected to a running cluster with a default StorageClass and LoadBalancer support (Minikube or AKS)
- Docker and the Azure CLI, only to build and push images

### Quick start (Minikube)

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

### Secrets

Secrets are never committed. Copy the template and fill in the values:

```sh
cp .env.example .env
```

| Key | Used by |
|---|---|
| `POSTGRES_PASSWORD` | postgres worker result |
| `REDIS_PASSWORD` | redis poll worker |

Azure credentials are not stored in the repository. Authenticate with `az login`.

### Azure infrastructure

| Resource | Value |
|---|---|
| Region | `belgiumcentral` |
| Resource group | `bernstein-rg` |
| Cluster | `bernstein-aks` |
| Registry | `bernsteineon.azurecr.io` |
| Namespace | `poll-app` |

Provisioning steps and subscription constraints: [docs/azure-setup.md](docs/azure-setup.md).

## Documentation

- **Deployment & Usage of the images**: [docs/deployment.md](docs/deployment.md)
- **Azure Setup & Infrastructure**: [docs/azure-setup.md](docs/azure-setup.md)

## Epitech warning

This project was built for the Epitech curriculum. **Epitech students: do not copy this code for your own project.** Copying is forbidden at Epitech and is treated as cheating. Read it to learn if you want, but write your own.

## Contributing

Contributions are welcome: read [CONTRIBUTING.md](CONTRIBUTING.md) and the [code of conduct](CODE_OF_CONDUCT.md).

## License

This project is licensed under the **MIT License**, see [LICENSE](LICENSE).

![BERNSTEIN License : MIT](https://img.shields.io/badge/License-MIT-blue.svg)
