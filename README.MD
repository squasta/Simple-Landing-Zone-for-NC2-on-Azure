## Nutanix Cloud Cluster (NC2) Simple Landing Zone for POC

This repo contains Terraform files to deploy all Azure network components needed to deploy Nutanix Cloud Cluster(NC2) on Azure Baremetal


## Prerequisites

- All prerequisites for NC2 : https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-getting-ready-for-deployment-c.html


- An Azure Subscription with enough privileges (create RG, AKS...)
- Azure CLI 2.37 or >: <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest>
   And you need to activate features that are still in preview and add extension aks-preview to azure CLI (az extension add --name aks-preview)
- Terraform CLI 1.5 or > : <https://www.terraform.io/downloads.html>

You can also clone this repo in your Azure Cloud Shell (that has all tools installed)



1. Terraform Init phase  

```bash
terraform init
```

2. Terraform Plan phase

```bash
terraform plan --var-file=configuration.tfvars
```

3. Terraform deployment phase (add TF_LOG=info at the beginning of the following command line if you want to see what's happen during deployment)

```bash
terraform apply --var-file=mconfiguration.tfvars
```

4. Wait until the end of deployment (It should take less than 1 minute)

5. Go to Nutanix NC2 Portal https://cloud.nutanix.com and start your Nutanix Cluster deployment wizard.

In steps 4 (Network), 5 (Prism Central) and 6 (Flow Networking) select the Virtuals Networks and Subnets created using terraform.

6. After the deployment is successfull, you can add connectivity with on-premises or other Azure VNet or services by peering Hub Vnet or Hub vWAN

