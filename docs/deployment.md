# Deployment & Usage

## Prerequisites

- `kubectl` connected to a running cluster with a default StorageClass and LoadBalancer support (any AKS cluster)
- Docker and the Azure CLI, only to build and push images

## Images

Images are hosted on Azure Container Registry. Pull is public, no login required.

| Service | Image |
|---|---|
| poll | `bernsteineon.azurecr.io/poll:87b6fe1` |
| result | `bernsteineon.azurecr.io/result:87b6fe1` |
| worker | `bernsteineon.azurecr.io/worker:87b6fe1` |

Check it without credentials:

```sh
docker pull bernsteineon.azurecr.io/poll:87b6fe1
```

## Usage

Every deployment targets the current `kubectl` context and prints the public URLs. Add `YES=1` to skip the confirmation.

### Deploy the published images

No Azure account or registry access required.

```sh
cp .env.example .env    # set both passwords
SKIP_BUILD=1 TAG=87b6fe1 ./scripts/deploy.sh aks
```

### Build, push and deploy

Requires `az login` with push access to the registry.

```sh
./scripts/deploy.sh aks
```

### Update without downtime

After a code change, build and push with an account that has push access:

```sh
./scripts/build.sh    # prints the new tag
./scripts/push.sh
```

Then deploy the new tag on the cluster. Replace `<new-tag>` with the printed value:

```sh
SKIP_BUILD=1 TAG=<new-tag> ./scripts/deploy.sh aks
```

### Minikube

```sh
minikube start
minikube addons enable metrics-server
./scripts/deploy.sh minikube
minikube tunnel    # in another terminal
```
