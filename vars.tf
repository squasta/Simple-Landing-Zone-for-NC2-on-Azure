
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

variable "EnableAzureBastion" {
  type = number
  description = "Enable Azure Bastion"
  default = 0
}

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