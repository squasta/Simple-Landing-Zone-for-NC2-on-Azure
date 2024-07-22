

#  __      __        _       _     _           
#  \ \    / /       (_)     | |   | |          
#   \ \  / /_ _ _ __ _  __ _| |__ | | ___  ___ 
#    \ \/ / _` | '__| |/ _` | '_ \| |/ _ \/ __|
#     \  / (_| | |  | | (_| | |_) | |  __/\__ \
#      \/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
#
#### VARIABLES DEFINITION with default values
#### please enter or check your values in configuration.tfvars  

# Resource Group Name where all resources will be created
variable "ResourceGroupName" {
  type = string
  description = "Resource Group Name"
}

# Azure Region Name
# cf. https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-regions
# Azure CLI command to get the list of Azure Regions :
# az account list-locations -o table
# Supported regions for Nutanix Clusters on Azure (NC2) :
#  https://learn.microsoft.com/en-us/azure/baremetal-infrastructure/workloads/nc2-on-azure/supported-instances-and-regions
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

# This is the list of DNS servers that will be used by the VNet for name resolution
# especially usefull for baremetal hosts and Prism Central VM to resolve names for connecting NC2 Portal (MCM Portal)
# In Azure, if you don't provide any DNS server, the default Azure DNS servers will be used (168.63.129.16)
# https://learn.microsoft.com/en-us/azure/virtual-network/what-is-ip-address-168-63-129-16
# using Google DNS (8.8.8.8), or Cloudflare (1.1.1.1) or Quad9 (9.9.9.9) is possible and more simple
# if you are using your own DNS server(s), be sure that communication is possible and Forwarding enabled to 
# resolve public DNS names
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

variable "ClusterVnetCIDR" {
  type = list(string)
  description = "CIDR for Cluster VNet"
  default = ["10.0.0.0/16"]  
}

variable "ClusterSubnetCIDR" {
  type = list(string)
  description = "CIDR for Cluster Subnet"
  default = ["10.0.1.0/24"]
  
}

variable "ClusterSubnetName" {
  type=string
  description = "Name of the subnet where hosts of cluster are connected"
}

variable "PCVnetName" {
  type = string
  description = "Name of VNet for PC, Flow Gateway"  
}

variable "PCVnetCIDR" {
  type = list(string)
  description = "CIDR for PC VNet"
  default = ["10.1.0.0/16"]
}

variable "PCSubnetName" {
  type = string
  description = "Name of Subnet for Prism Central (PC)"  
}

variable "PCSubnetCIDR" {
  type = list(string)
  description = "CIDR for PC Subnet"
  default = ["10.1.1.0/24"] 
}


variable "FgwExternalSubnetName" {
  type = string
  description = "Name of External Subnet in PC VNet for Flow Gateway"  
}

variable "FgwExternalSubnetCIDR" {
  type = list(string)
  description = "CIDR for External Subnet in PC VNet for Flow Gateway"
  default = ["10.1.2.0/24"]
  
}

variable "FgwInternalSubnetName" {
  type = string
  description = "Name of Internal Subnet in PC VNet for Flow Gateway"  
}

variable "FgwInternalSubnetCIDR" {
  type = list(string)
  description = "CIDR for Internal Subnet in PC VNet for Flow Gateway"
  default = ["10.1.3.0/24"]
}

variable "BGPSubnetName" {
  type = string
  description = "Name of BGP Subnet in PC VNet for BGP VM"  
}

variable "BGPSubnetCIDR" {
  type = list(string)
  description = "CIDR for BGP Subnet in PC VNet for BGP VM"
  default = ["10.1.4.0/24"]
}

variable "AzureBastionSubnetCIDR" {
  type = list(string)
  description = "CIDR for Azure Bastion Subnet"
  default = ["10.1.5.0/26"]
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

# Enable a Virtual Machine for testing network connectivity to Hub VNet
# 0 = disabled, 1 = enabled
variable "EnableVM4testingNetwork_HubVnet" {
  type = number
  description = "Enable a Virtual Machine for testing network connectivity to Hub VNet"
  default = 0
}