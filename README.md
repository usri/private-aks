# Private AKS

This sample provides guidance and code to run a [private AKS cluster](https://docs.microsoft.com/en-us/azure/aks/private-clusters). This solution builds on the great work from [Pavel Tuzov](https://github.com/patuzov/terraform-private-aks), and then modifies the solution to meet some of the requirements of our Azure Government customers. Some of the modifications to Pavel's original work include

- Replace the Jumpbox VM with an Azure Container Instance running `azure-cloudshell` that is attached to the VNET
  - Includes a premium file share volume mounted for persistent storage.
- [TODO](https://github.com/microsoft/federal-app-innovation/issues/37): Include a private Azure Container Registry (ACR)

## Architecture

The architecture shown below represents the environment that will be deployed. It is a hub-and-spoke deployment where all resources are private to the networks they are deployed in.

![Private-AKS-Architecture](/assets/private-aks-arch.png)

The `jumpbox-subnet` contains and Azure Container Instance (ACI) running the `azure-cloudshell` image. This ACI serves as a host whereby an IT/DevOps engineer can perform management services. In traditional architectures, this would be a bastion/jumpbox VM. The `azure-cloudshell` mounts a file share to persist files/tools, such as, credentials to the AKS cluster and/or tools you may use to manage the environment.

The `firewall-subnet` contains an Azure Firewall with route tables to allow/deny egress traffic to known hosts, such as a container registry, Azure management endpoints, or other public endpoints the AKS cluster should be allowed to access.

The hub and spoke virtual networks are peered to support the traffic flow to/from the AKS cluster.

## Pre-Requisites

The following software needs to be installed on your local computer before you start.

- Azure Subscription (commercial or government)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli), v2.18 (or newer)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli), v1.0.x

> Deployment of this solution has been tested on _Ubuntu 18.04_, _Ubuntu 20.04_, and _Windows Server 2019 Datacenter_.

This solution uses Terraform to describe and deploy a hub and spoke architecture.

## Get Started

To get started, you need to perform the following tasks in order:

- Configure your environment
- Deploy the solution to Azure

### Configure your environment

Before deploying the Terraform template, you should modify `./private-aks/variables.tf` to customize your deployment. For example, you may want to change the location/region the template deploys or the version of AKS.

> NOTE: For deployments into Azure Government subscriptions, you must set your region to `usgovvirginia` or `usgovarizona`.  These are the only two regions that support Azure Container Instances (ACI).  **Last verified on May 12, 2021**.

### Deploy the solution to Azure

To deploy the solution, perform the following steps:

```bash
# If deploying to an Azure Government subscription, then run this command
az cloud set --name AzureUSGovernment

# Login to your Azure Subscription
az login

# Make sure you're in the root folder of the repo
cd ./private-aks

# Deploy the solution
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
```

> NOTE: Deployment will take about 20 minutes to complete.

## Using your deployment

There are a few things you can do to verify your environment is working, such as

- Connect to the `azure-cloudshell` running in ACI to perform bastion type services
- Build and push an image to ACR
- Deploy a sample workload to AKS

The following sections will guide you through each of these.

### Connect to and use the `azure-cloudshell` container instance

The container instance is running an Azure Cloud Shell container. This is the same Azure Cloud Shell used in the Azure portal. The purpose of running this in ACI like this is to provide a _secure_ and _private_ host from which you can perform bastion/jumpbox types of operations. In the past, this would have been accomplished using a hardened VM that you could RDP or SSH into. However, that introduces unnecessary overhead, risks, and costs.

Below are some commands to get started using the `azure-cloudshell`. You can run these from the Azure Cloud Shell in the portal or from a terminal window on your local computer.

```bash
# Check the status of the azure-cloudshell (ie: should be "Running" after deployment)
az container show --resource-group hub-rg --name mgmt-acg --query "containers[?name=='azure-cloud-shell'].instanceView.currentState.state" --output tsv

# Connect to the azure-cloudshell running in ACI
# - To exit the shell, type 'exit' at the terminal prompt
az container exec --resource-group hub-rg --name mgmt-acg --container-name azure-cloud-shell --exec-command "/bin/sh"

# Stop the azure-cloudshell
az container stop --name mgmt-acg --resource-group hub-rg

# Start the azure-cloudshell
# - Note: It takes a few minutes for the container to reach a "Running" status
az container start --name mgmt-acg --resource-group hub-rg

# Store some data the mounted volume (file share)
cd /data  # This is the mount-path that was specified in the Terraform template.
cat > helloworld.txt
  # type some text
  # press ctrl-d to save the file
ll # show the file

# Retrieve AKS credentials from the cluster in the spoke and store them in the volume mount.
# - Only need to do this one time.
az login
az aks get-credentials --resource-group spoke1-rg --name private-aks --file /data/.kube/config

# Use the kubeconfig persisted in the volume mount.
# - For example, after starting a new session in the azure-cloudshell instance
kubectl config use-context private-aks --kubeconfig /data/.kube/config
```

### Build and push an image to ACR

[TODO](https://github.com/microsoft/federal-app-innovation/issues/37)

### Deploy a sample workload to AKS

[TODO](https://github.com/microsoft/federal-app-innovation/issues/37)

## FAQ

### Why are random characters inserted in the prompts when I SSH into the azure-cloudshell container instance?

This is a [known issue](https://github.com/Azure/azure-cli/issues/6537). This happens whether you connect to the cloudshell from the Azure portal or locally from your terminal window. There are a couple of workarounds [here](https://github.com/Azure/azure-cli/issues/6537#issuecomment-442350790) and [here](https://github.com/Azure/azure-cli/issues/6537#issuecomment-448967579) in the referenced issue that you can try.

### When using kubectl from within azure-cloudshell (ACI), I get the following message _"The connection to the server localhost:8080 was refused - did you specify the right host or port?"_

This will happen if your current working directory is the volume mounted from the Azure File Share (ie: `/data`). Change directory back to your home directory (ie: `cd ~`) and it should work again.

### I get permission denied if I try to view the Azure File Share using the Azure Portal or Storage Explorer. How can I see the files in the file share?

This is by design - remember, this is a private environment. So, unless you're looking at the File Share from within the `azure-cloudshell` (ACI), you're not going to have access by default. If you want to override this behavior, you can whitelist _your_ client IP in the storage account so you can see the files.

- To do this from the portal, open the storage account in the resource group `hub-rg`. Under _Settings_, click on **Networking**. In the Networking blade, check the box labeled _"Add your client IP address"_ under the Firewall section and click _Save_ at the top.
- To do this using the CLI, run the following command:
  ```bash
  az storage account network-rule add --resource-group "hub-rg" --account-name "[your storage account name]" --ip-address "[your IP address]"
  ```

## References

The resources below provide additional details that influenced this reference architecture.

- [Private AKS Terraform](https://github.com/patuzov/terraform-private-aks) provided the foundation for this solution.
- [Terraform: Dynamically appy service-delegation to subnet](https://discuss.hashicorp.com/t/dynamic-block-used-together-with-count/9329)
- [Connect privately to Azure Container Registry using Private Link](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-private-link)
- [Error creating file share in storage account bound to VNET](https://github.com/terraform-providers/terraform-provider-azurerm/issues/1764)
