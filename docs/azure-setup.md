# Azure setup

How to provision the Kubernetes cluster and the private registry used by this project on Azure Kubernetes Service (AKS) and Azure Container Registry (ACR).

## Prerequisites

- Azure CLI (`az`)
- `kubectl`
- Docker
- An Azure subscription (this project uses *Azure for Students*)

## Variables

Every command below uses these values. Change them if the names are already taken or if your subscription allows other regions.

```sh
RG=bernstein-rg
LOCATION=belgiumcentral
ACR=bernsteineon            # globally unique, lowercase letters and digits only
AKS=bernstein-aks
NODE_SIZE=Standard_D2as_v4
```

Steps 1 to 4 and 9 are run once by the subscription owner. A teammate only runs step 6.

## 1. Log in

```sh
az login
az account set --subscription <subscription-id>
```

Use the subscription ID rather than its name. Several subscriptions can share the name *Azure for Students*.

## 2. Register the resource providers

Required once per subscription. Without it quota queries return nothing and resource creation fails.

```sh
for p in Microsoft.Compute Microsoft.ContainerService Microsoft.ContainerRegistry \
         Microsoft.Network Microsoft.Storage Microsoft.OperationalInsights; do
  az provider register --namespace "$p"
done
```

Wait until every provider shows `Registered`:

```sh
az provider list --query "[?starts_with(namespace,'Microsoft.')].{ns:namespace, state:registrationState}" -o table
```

## 3. Subscription constraints

The *Azure for Students* subscription restricts regions, VM sizes and vCPU quota. The values above were chosen to satisfy all three.

| Constraint | Value | How to check |
|---|---|---|
| Allowed regions | `norwayeast` `switzerlandnorth` `austriaeast` `belgiumcentral` `italynorth` | `az policy assignment list --query "[].parameters.listOfAllowedLocations.value" -o json` |
| Total regional vCPUs | 6 | `az vm list-usage -l $LOCATION -o table` |
| Usable 2 vCPU sizes | Only `belgiumcentral` offers sizes that are both allowed and covered by quota (`D2as_v4` `D2s_v4`) | `az vm list-skus -l $LOCATION --size Standard_D2 -o table` |
| `DASv4` family quota | 4 vCPUs, so exactly 2 nodes of `Standard_D2as_v4` | `az vm list-usage -l $LOCATION -o table` |

Consequences:

- The node pool cannot grow beyond 2 nodes.
- Node pool upgrades need a surge node that the quota cannot provide (see step 7).
- If `Standard_D2as_v4` is refused use `Standard_D2s_v4`. It has its own 4 vCPU quota.

## 4. Create the resources

```sh
az group create -n $RG -l $LOCATION

az acr create -g $RG -n $ACR --sku Basic

az aks create -g $RG -n $AKS \
  --node-count 2 --node-vm-size $NODE_SIZE \
  --node-osdisk-size 30 \
  --tier free \
  --node-os-upgrade-channel Unmanaged \
  --attach-acr $ACR \
  --generate-ssh-keys
```

| Option | Reason |
|---|---|
| `--tier free` | No charge for the control plane |
| `--node-os-upgrade-channel Unmanaged` | Node image upgrades cannot run within the quota (see step 7) |
| `--node-osdisk-size 30` | Smaller OS disk is enough and reduces cost |
| `--attach-acr` | Grants the cluster managed identity pull access to the registry. No `imagePullSecret` and no registry password are needed. |

The registry admin account stays disabled. Humans authenticate with their Azure account and the cluster with its managed identity.

`--attach-acr` grants `AcrPull` on this registry only. If the registry is recreated the role is lost and pods fail with `ImagePullBackOff` (`401 Unauthorized`). Check and restore it:

```sh
az aks check-acr -g $RG -n $AKS --acr $ACR.azurecr.io
az aks update -g $RG -n $AKS --attach-acr $ACR
```

## 5. Connect `kubectl`

```sh
az aks get-credentials -g $RG -n $AKS
kubectl config use-context $AKS
kubectl get nodes
```

Two nodes must be `Ready`. Always check the active context before applying anything:

```sh
kubectl config current-context
```

## 6. Grant a teammate access

```sh
az role assignment create \
  --assignee <teammate-email> \
  --role Contributor \
  --scope "$(az group show -n $RG --query id -o tsv)"
```

The role only covers the resource group. Subscription level commands such as `az provider register` return `AuthorizationFailed` for the teammate, which is expected.

The teammate then runs:

```sh
az login
az account set --subscription <owner-subscription-id>
az aks get-credentials -g $RG -n $AKS
```

Without `az account set` the CLI may target the teammate's own subscription and every command fails with `AuthorizationFailed`.

## 7. Disable automatic node image upgrades

A node image upgrade adds a temporary surge node. A system node pool requires `maxUnavailable: 0` so the surge node cannot be avoided. With a 4 vCPU family quota the third node cannot be created and the upgrade fails.

The cluster only lives for the duration of the project so node image upgrades are disabled at creation. OS security patches are still applied in place by the nodes.

Any operation that reconciles the node pool also needs a surge node. To change node pool settings on an existing cluster scale it down to one node first:

```sh
az aks scale  -g $RG -n $AKS --node-count 1
az aks update -g $RG -n $AKS --node-os-upgrade-channel Unmanaged
az aks scale  -g $RG -n $AKS --node-count 2
```

## 8. Push images

```sh
az acr login -n $ACR
docker push $ACR.azurecr.io/<image>:<tag>
```

## 9. Allow anonymous pull

The evaluator deploys the images on his own cluster without an Azure account. Anonymous pull requires the Standard SKU.

```sh
az acr update -n $ACR --sku Standard
az acr update -n $ACR --anonymous-pull-enabled true
```

Check it without credentials:

```sh
docker logout $ACR.azurecr.io
docker pull $ACR.azurecr.io/poll:<tag>
```

- Pull is public. Push still requires an Azure role on the registry.
- Anonymous clients can pull and list repositories and tags through the registry API. `az acr repository` commands still require a login. The tag to deploy is given in [deployment.md](deployment.md).
- Switch back to Basic after the evaluation: `az acr update -n $ACR --sku Basic`.

## 10. Cost management

| Action | Command | Billing |
|---|---|---|
| Stop the cluster | `scripts/aks.sh stop` | VMs stop being billed. Registry and public IPs still are. |
| Start the cluster | `scripts/aks.sh start` | |
| Delete everything | `az group delete -n $RG --yes` | Nothing left. Also removes the `MC_*` node resource group. |

`scripts/aks.sh` waits for any pending start or stop. After a start it also waits until the API server answers, which takes 1 to 2 minutes.

- Two `Standard_D2as_v4` nodes cost about 5 USD per day while running.
- The registry costs about 0.17 USD per day on Basic and 0.67 USD per day on Standard.
- Stop the cluster whenever it is not in use. Develop and test on Minikube first.
- Set a budget alert in *Cost Management > Budgets*.
