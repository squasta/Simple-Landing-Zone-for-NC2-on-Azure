
####
#### VARIABLES DEFINITION
#### please enter or check your values in configuration.tfvars
####

variable "ResourceGroupName" {
  type = string
  description = "Resource Group Name"
}

variable "Location" {
  type = string
  description = "Azure Region Name"
  # cf. https://developer.hashicorp.com/terraform/language/expressions/custom-conditions#input-variable-validation
  validation {
    condition = contains(["eastus", "eastus2", "westus", "westus2", "centralus", "northcentralus", "southcentralus", "westcentralus", "canadacentral", "canadaeast", "brazilsouth", "northeurope", "westeurope", "eastasia", "southeastasia", "japanwest", "japaneast", "australiaeast", "australiasoutheast", "australiacentral", "australiacentral2", "southindia", "centralindia", "westindia", "koreacentral", "koreasouth", "ukwest", "uksouth", "francecentral", "francesouth", "norwayeast", "norwaywest", "switzerlandnorth", "switzerlandwest", "germanywestcentral", "germanynorth", "germanynortheast", "uaenorth", "uaecentral", "southafricanorth", "southafricawest", "eastus2euap", "westus3", "southeastasia2", "brazilsoutheast", "australiacentral", "australiasoutheast", "japaneast2", "koreasouth2", "southindia", "centralindia", "westindia", "southafricanorth", "southafricawest", "norwayeast", "norwaywest", "switzerlandnorth", "switzerlandwest", "germanywestcentral", "germanynorth", "germanynortheast", "uaenorth", "uaecentral", "southafricanorth", "southafricawest", "eastus2euap", "westus3", "southeastasia2", "brazilsoutheast", "australiacentral", "australiasoutheast", "japaneast2", "koreasouth2", "southindia", "centralindia", "westindia", "southafricanorth", "southafricawest", "norwayeast", "norwaywest", "switzerlandnorth", "switzerlandwest", "germanywestcentral", "germanynorth", "germanynortheast", "uaenorth"], var.Location)
    error_message = "Invalid Azure Region Name"
  }
}

variable "ClusterVnetName" {
  type = string
  description = "Name of VNet for NC2 Hosts"
}

variable "vnet_dns_adresses" {
  default = [
    "8.8.8.8",
    "1.1.1.1"
  ]
  validation {
    condition = length(var.vnet_dns_adresses) > 0
    error_message = "At least one DNS server must be provided"
  }
}

variable "ClusterSubnetName" {
  type=string
  description = "Name of the subnet where hosts of cluster are connected"
}

variable "PCVnetName" {
  type = string
  description = "Name of VNet for PC, Flow Gateway"  
}

variable "PCSubnetName" {
  type = string
  description = "Name of Subnet for Prism Central (PC)"  
}

variable "FgwExternalSubnetName" {
  type = string
  description = "Name of External Subnet in PC VNet for Flow Gateway"  
}

variable "FgwInternalSubnetName" {
  type = string
  description = "Name of Internal Subnet in PC VNet for Flow Gateway"  
}

variable "BGPSubnetName" {
  type = string
  description = "Name of BGP Subnet in PC VNet for BGP VM"  
}

variable "NATGwClusterName" {
  type = string
  description = "Name of NAT Gateway for Cluster Baremetal host"  
}

variable "PublicIPClusterName" {
  type = string
  description = "Name of Azure Public IP used by NAT Gateway in Cluster VNet"    
}

variable "NATGwPCName" {
  type = string
  description = "Name of NAT Gateway for PC VNet (PC and External FGW subnets)"  
}

variable "PublicIPPCName" {
  type = string
  description = "Name of Azure Public IP used by NAT Gateway in PC VNet"    
}

variable "PublicBastionIPName" {
  type = string
  description = "Name of Azure Public IP used by Azure Bastion"    
}

variable "AzureBastionHostName" {
  type = string
  description = "Name of Azure Bastion host"    
}

variable "AdminUsername" {
  type = string
  description = "Admin Username for VM"
}

# Please read that : https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables
# and that : https://learn.hashicorp.com/tutorials/terraform/sensitive-variables
variable "AdminPassword" {
  type = string
  description = "Admin Password for VM"
  sensitive   = true
}

variable "VMBastionNicName" {
  type = string
  description = "Name of NIC for Bastion VM"
}

variable "VMJumpboxName" {
  type = string
  description = "Name of Jumpbox VM"
}

variable "HostnameVMJumbox" {
  type = string
  description = "Hostname of Jumpbox VM"
}

# Enable the creation of Azure Bastion
# 0 = disabled, 1 = enabled
variable "EnableAzureBastion" {
  type = number
  description = "Enable Azure Bastion"
  default = 0
}

# Enable the creation of a Jumpbox VM
# 0 = disabled, 1 = enabled
variable "EnableJumboxVM" {
  type = number
  description = "Enable Azure Bastion"
  default = 0
}

# You can get the list of VM sizes in Azure for a specific region using the following command :
# az vm list-sizes --location westeurope --output table
# If you don't have the Azure CLI tool on your machine, you can use the Azure Cloud Shell 
# in Azure portal to run the command. https://shell.azure.com/ is also an option.
variable "AzureVMSize" {
  type = string
  description = "Size of Azure VM"
  default = "Standard_B2ms"
}


## Azure Bastion SKU
# The Azure Bastion SKU to use. Possible values are Developer, Basic, Standard or Premium.
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/bastion_host
# Developper SKU is free of charge
# Developer SKU is available in the following Azure Region
# Central US EUAP, East US 2 EUAP, West Central US, North Central US, West US, North Europe
variable "AzureBastionSKU" {
  type = string
  description = "Azure Bastion SKU"
  default = "Basic"
}


## Hub VNet name
variable "HubVNetName" {
  type = string
  description = "A VNet named Hub-VNet"
}

## VPN site to site Shared Key
variable "VPNSiteToSiteSharedKey" {
  type = string
  description = "Shared Key for VPN Site to Site"
  sensitive = true
}


# Enable a Virtual Machine for testing network connectivity to On-Premises
# 0 = disabled, 1 = enabled
variable "EnableVM4testingNetwork_OnPremises" {
  type = number
  description = "Enable a Virtual Machine for testing network connectivity to On-Premises"
  default = 0
}
