
#### LANDING ZONE FOR NC2 on Azure (version 1) - Stanislas
####
####            __|__
####     --o--o--(_)--o--o--
####
#### improvements to do
#### make variable for peering names
#### make variable for VNET IP range and Subnets Adresse space


### MUST READ THIS :
### Networking infrastructure in Azure : https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-setting-up-networking-infrastructure-in-azure-c.html
### VNets, Subnets and NAT Gateway : https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-configuring-vnets-subnets-and-nat-gateway-t.html
### VNet and SubNet : https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-creating-a-vnet-and-subnet-in-azure-t.html
### NAT Gateway : https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-creating-a-nat-gateway-in-azure-t.html



###
### DEFINITION OF MANDATORY NETWORK RESOURCES FOR NC2 Cluster deployment in Azure
###


# Ressource Group
resource "azurerm_resource_group" "TF_RG" {
  name     = var.ResourceGroupName
  location = var.Location
}


# Cluster VNET  (for Baremetal hosts)
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
# NC2 does not support Use of 192.168.5.0/24 CIDR for the VNet being used to deploy the NC2 on Azure cluster
# All Nutanix nodes use that CIDR for communication between the CVM and the installed hypervisor.
# cf. https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-getting-ready-for-deployment-c.html
resource "azurerm_virtual_network" "TF_Cluster_VNet" {
  name                = var.ClusterVnetName
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name
  address_space       = var.ClusterVnetCIDR
  dns_servers         = var.vnet_dns_adresses    
}


# Bare metal Subnet with delegation to Azure Bare
# This subnet must be delegated to a servive named Microsoft.BareMetal/AzureHostedService
# This Subnet must associated with an Azure NAT Gateway 
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet

resource "azurerm_subnet" "TF_SubNet_Cluster" {
  name                 = var.ClusterSubnetName
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_Cluster_VNet.name
  address_prefixes     = var.ClusterSubnetCIDR
  # private_endpoint_network_policies_enabled = false

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.BareMetal/AzureHostedService"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Azure NAT Gateway for Cluster VNet (Subnet Baremetal hosts)
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway
# cf. https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-creating-a-nat-gateway-in-azure-t.html
resource "azurerm_nat_gateway" "TF_NATGw_Cluster" {
  name                    = var.NATGwClusterName
  location                = azurerm_resource_group.TF_RG.location
  resource_group_name     = azurerm_resource_group.TF_RG.name
  sku_name                = "Standard"  # this is the only option available now
  tags = {
    fastpathenabled = "true"
  }
}


# Azure Public IP for NAT Gateway Cluster
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
resource "azurerm_public_ip" "TF_NATGw_PublicIP_Cluster" {
  name                = var.PublicIPClusterName
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


# NAT Gateway (Cluster) and Public IP (Cluster) Association
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association
resource "azurerm_nat_gateway_public_ip_association" "TF_NATGw_PublicIP_Association_Cluster" {
  nat_gateway_id       = azurerm_nat_gateway.TF_NATGw_Cluster.id
  public_ip_address_id = azurerm_public_ip.TF_NATGw_PublicIP_Cluster.id
}


# Subnet and NAT Gateway Association
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association
resource "azurerm_subnet_nat_gateway_association" "TF_Subnet_NATGw_Association_Cluster" {
  subnet_id      = azurerm_subnet.TF_SubNet_Cluster.id
  nat_gateway_id = azurerm_nat_gateway.TF_NATGw_Cluster.id
}


# PC VNet 
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
# NC2 does not support Use of IPs 192.168.0.0/16, 10.100.0.0/16, 10.200.0.0/24, or 10.200.0.0/22 for Prism Central VNet
# cf. https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-getting-ready-for-deployment-c.html
resource "azurerm_virtual_network" "TF_PC_VNet" {
  name                = var.PCVnetName
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name
  address_space       = var.PCVnetCIDR
  dns_servers         = var.vnet_dns_adresses      
}


# Subnet cluster-pc
# This subnet is for Prismn Central in PC VNet
# This subnet must be delegated to a servive named Microsoft.BareMetal/AzureHostedService
# This Subnet must associated with an Azure NAT Gateway 
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "TF_Subnet_Cluster_PC" {
  name                 = var.PCSubnetName
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_PC_VNet.name
  address_prefixes     = var.PCSubnetCIDR
  # private_endpoint_network_policies_enabled = false

  delegation {
  name = "delegation"

    service_delegation {
      name    = "Microsoft.BareMetal/AzureHostedService"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


# Subnet fgw-external-subnet
# This subnet is external subnet where is connected external NIC of Flow Gateway (that is an Azure Virtual Machine)
# This Subnet must associated with an Azure NAT Gateway 
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "TF_Fgw_External_Subnet" {
  name                 = var.FgwExternalSubnetName
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_PC_VNet.name
  address_prefixes     = var.FgwExternalSubnetCIDR
  # private_endpoint_network_policies_enabled = false
}


# Subnet fgw-internal-subnet
# This subnet is internal subnet where is connected internal NIC of Flow Gateway (that is an Azure Virtual Machine)
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "TF_Fgw_Internal_Subnet" {
  name                 = var.FgwInternalSubnetName
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_PC_VNet.name
  address_prefixes     = var.FgwInternalSubnetCIDR
  # private_endpoint_network_policies_enabled = false
}


# Subnet bgp-subnet
# This subnet is BGP subnet where are connected BGP Speaker/GW (that are Azure Virtual Machine)
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
# cf. https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-networking-configurations-c.html 
resource "azurerm_subnet" "TF_BGP_Subnet" {
  name                 = var.BGPSubnetName
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_PC_VNet.name
  address_prefixes     = var.BGPSubnetCIDR
  # private_endpoint_network_policies_enabled = false
}

# Subnet AzureBastionSubnet
# This subnet is for Azure Bastion
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
# more info on Azure Bastion : https://docs.microsoft.com/en-us/azure/bastion/bastion-create-host-portal
resource "azurerm_subnet" "TF_Azure_Bastion_Subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_PC_VNet.name
  address_prefixes     = var.AzureBastionSubnetCIDR
  # private_endpoint_network_policies_enabled = false
}


# Azure NAT Gateway for PC VNet (attached to FgwExternalSubnet and PCSubnet)
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway
# cf. https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-creating-a-nat-gateway-in-azure-t.html
resource "azurerm_nat_gateway" "TF_NATGw_PC" {
  name                    = var.NATGwPCName
  location                = azurerm_resource_group.TF_RG.location
  resource_group_name     = azurerm_resource_group.TF_RG.name
  sku_name                = "Standard"  # this is the only option available now
  tags = {
    fastpathenabled = "true"
  }
}


# Azure Public IP for NAT Gateway PC
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
resource "azurerm_public_ip" "TF_NATGw_PublicIP_PC" {
  name                = var.PublicIPPCName
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


# NAT Gateway (Cluster) and Public IP (Cluster) Association
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association
resource "azurerm_nat_gateway_public_ip_association" "TF_NATGw_PublicIP_Association_PC" {
  nat_gateway_id       = azurerm_nat_gateway.TF_NATGw_PC.id
  public_ip_address_id = azurerm_public_ip.TF_NATGw_PublicIP_PC.id
}


# Subnet and NAT Gateway Association (PC NAT GW + PC Subnet)
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association
resource "azurerm_subnet_nat_gateway_association" "TF_Subnet_NATGw_Association_Cluster_PC" {
  subnet_id      = azurerm_subnet.TF_Subnet_Cluster_PC.id
  nat_gateway_id = azurerm_nat_gateway.TF_NATGw_PC.id
}


# Subnet and NAT Gateway Association (PC NAT GW + FGW external Subnet)
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association
resource "azurerm_subnet_nat_gateway_association" "TF_Subnet_NATGw_Association_PC" {
  subnet_id      = azurerm_subnet.TF_Fgw_External_Subnet.id
  nat_gateway_id = azurerm_nat_gateway.TF_NATGw_PC.id
}


# Peering between Cluster VNet and PC VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering

resource "azurerm_virtual_network_peering" "TF_Peering_Cluster2PC" {
  name                      = "Peer-ClusterVNet-to-PCVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_Cluster_VNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_PC_VNet.id
}


# Peering between PC VNet and Cluster VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering
resource "azurerm_virtual_network_peering" "TF_Peering_PC2Cluster" {
  name                      = "Peer-PCVNet-to-ClusterVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_PC_VNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_Cluster_VNet.id
  depends_on = [ azurerm_virtual_network_peering.TF_Peering_Cluster2PC ]
}
