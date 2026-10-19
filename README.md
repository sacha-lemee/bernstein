# Bernstein

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
