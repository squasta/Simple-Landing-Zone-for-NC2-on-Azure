
# A VNet named Hub-VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network

resource "azurerm_virtual_network" "TF_HubVNet" {
  name                = var.HubVNetName
  location            = var.Location
  resource_group_name = azurerm_resource_group.TF_RG.name
  address_space       = ["172.16.0.0/16"]

    tags = {
        environment = "Hub"
    }
}


# A Subnet in Hub VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
# https://www.ipaddressguide.com/cidr 

resource "azurerm_subnet" "TF_HubSubnet" {
  name                 = "HubSubnet"
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_HubVNet.name
  address_prefixes     = ["172.16.0.0/24"]
}


# A Subnet in Hub VNet for VPN Gateway
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet

resource "azurerm_subnet" "TF_HubVPNGWSubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_HubVNet.name
  address_prefixes     = ["172.16.250.0/27"]
}


# A Public IP for VPN Gateway in Hub VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip

resource "azurerm_public_ip" "TF_HubVPNGWPublicIP" {
  name                = "Hub-VPNGW-PublicIP"
  location            = var.Location
  resource_group_name = azurerm_resource_group.TF_RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


# A VPN Gateway in Hub VNet in GatewaySubnet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway
# Important : deploying a new VPN Gateway needs about 30-45 minutes for deployment

resource "azurerm_virtual_network_gateway" "TF_HubVPNGW" {
  name                = "Hub-VPNGW"
  location            = var.Location
  resource_group_name = azurerm_resource_group.TF_RG.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false

  ip_configuration {
    name                          = "HubGWIPConfig"
    public_ip_address_id          = azurerm_public_ip.TF_HubVPNGWPublicIP.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.TF_HubVPNGWSubnet.id
  }

}

## Local gateway for Hub VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/local_network_gateway
# The local network gateway is a specific object that represents your on-premises location (the site) for routing purposes.
# The local network gateway object is deployed in Azure, not to your on-premises location.
# When you created that VPN connection and identified the subnets in your on prem environment, 
# Azure auto creates routes as system defaults

resource "azurerm_local_network_gateway" "TF_HubLocalGW" {
  name                = "Hub-LocalGW"
  location            = var.Location
  resource_group_name = azurerm_resource_group.TF_RG.name
  gateway_address  = azurerm_public_ip.TF_OnPremVPNGWPublicIP.ip_address
  address_space = ["192.168.250.0/24"]
}


# Peering between Cluster VNet and hub Vnet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering
resource "azurerm_virtual_network_peering" "TF_Peering_Cluster2Hub" {
  name                      = "Peer-ClusterVNet-to-HubVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_Cluster_VNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_HubVNet.id
  allow_virtual_network_access = true
  use_remote_gateways = true
  # `allow_gateway_transit` must be set to false for vnet Global Peering
  depends_on = [ azurerm_virtual_network.TF_HubVNet, azurerm_virtual_network.TF_Cluster_VNet ]
  timeouts {
    create = "45m"
  }
}

# Peering between Hub Vnet and Cluster Vnet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering
# cf. https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-peering-gateway-transit

resource "azurerm_virtual_network_peering" "TF_Peering_Hub2Cluster" {
  name                      = "Peer-HubVNet-to-ClusterVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_HubVNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_Cluster_VNet.id
  allow_virtual_network_access = true
  allow_gateway_transit = true
  depends_on = [ azurerm_virtual_network.TF_HubVNet, azurerm_virtual_network.TF_Cluster_VNet, azurerm_virtual_network_peering.TF_Peering_Cluster2Hub ]
  timeouts {
    create = "45m"
  }
}


# Peering between PC Vnet and hub Vnet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering
# cf. https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-peering-gateway-transit
resource "azurerm_virtual_network_peering" "TF_Peering_PC2Hub" {
  name                      = "Peer-PCVNet-to-HubVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_PC_VNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_HubVNet.id
  allow_virtual_network_access = true
  use_remote_gateways = true
  # `allow_gateway_transit` must be set to false for vnet Global Peering
  depends_on = [ azurerm_virtual_network.TF_HubVNet, azurerm_virtual_network.TF_PC_VNet, azurerm_virtual_network_gateway.TF_HubVPNGW ]
  timeouts {
    create = "60m"
  }
}


# Peering between Hub Vnet and PC Vnet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering

resource "azurerm_virtual_network_peering" "TF_Peering_Hub2PC" {
  name                      = "Peer-HubVNet-to-PCVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_HubVNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_PC_VNet.id
  allow_virtual_network_access = true
  allow_gateway_transit = true
  depends_on = [ azurerm_virtual_network.TF_HubVNet, azurerm_virtual_network.TF_PC_VNet, azurerm_virtual_network_peering.TF_Peering_PC2Hub  ]
  timeouts {
    create = "45m"
  }
}



# Peering between FGW Vnet and Hub Vnet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering

resource "azurerm_virtual_network_peering" "TF_Peering_FGW2Hub" {
  name                      = "Peer-FGWVNet-to-HubVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_FGW_VNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_HubVNet.id
  allow_virtual_network_access = true
  use_remote_gateways = true
  depends_on = [ azurerm_virtual_network.TF_HubVNet, azurerm_virtual_network.TF_FGW_VNet, azurerm_virtual_network_gateway.TF_HubVPNGW ]
  timeouts {
    create = "60m"
  }
}

# Peering between Hub Vnet and FGW Vnet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering

resource "azurerm_virtual_network_peering" "TF_Peering_Hub2FGW" {
  name                      = "Peer-HubVNet-to-FGWVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_HubVNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_FGW_VNet.id
  allow_virtual_network_access = true
  allow_gateway_transit = true
  depends_on = [ azurerm_virtual_network.TF_HubVNet, azurerm_virtual_network.TF_FGW_VNet, azurerm_virtual_network_peering.TF_Peering_FGW2Hub ]
  timeouts {
    create = "45m"
  }
}






# ----------------- "DATACENTER ON PREMISES" -----------------

## Datacenter On prem VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network

resource "azurerm_virtual_network" "TF_OnPremVNet" {
  name                = "OnPrem-VNet"
  location            = var.Location
  resource_group_name = azurerm_resource_group.TF_RG.name
  address_space       = ["192.168.250.0/24"]

}

# A Subnet in OnPrem VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet

resource "azurerm_subnet" "TF_OnPremSubnet" {
  name                 = "OnPremSubnet"
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_OnPremVNet.name
  address_prefixes     = ["192.168.250.0/25"]
}

# A SUBNET in OnPrem VNet for VPN Gateway
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet

resource "azurerm_subnet" "TF_OnPremVPNGWSubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_OnPremVNet.name
  address_prefixes     = ["192.168.250.128/25"]
}


# A Public IP for VPN Gateway in OnPrem VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip

resource "azurerm_public_ip" "TF_OnPremVPNGWPublicIP" {
  name                = "OnPrem-VPNGW-PublicIP"
  location            = var.Location
  resource_group_name = azurerm_resource_group.TF_RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


# A VPN Gateway in OnPrem VNet in GatewaySubnet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway
# Important : deploying a new VPN Gateway needs about 30-45 minutes for deployment

resource "azurerm_virtual_network_gateway" "TF_OnPremVPNGW" {
  name                = "OnPrem-VPNGW"
  location            = var.Location
  resource_group_name = azurerm_resource_group.TF_RG.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false

  ip_configuration {
    name                          = "OnPremGWIPConfig"
    public_ip_address_id          = azurerm_public_ip.TF_OnPremVPNGWPublicIP.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.TF_OnPremVPNGWSubnet.id
  }

}


## Local gateway for Onprem VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/local_network_gateway
# The local network gateway is a specific object that represents your Hub (the Vnet) for routing purposes

resource "azurerm_local_network_gateway" "TF_OnPremLocalGW" {
  name                = "OnPrem-LocalGW"
  location            = var.Location
  resource_group_name = azurerm_resource_group.TF_RG.name
  gateway_address  = azurerm_public_ip.TF_HubVPNGWPublicIP.ip_address
  address_space = ["172.16.0.0/24"]
}


# VPN Connection between on prem and hub
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection

resource "azurerm_virtual_network_gateway_connection" "TF_OnPremHubConn" {
  name                = "OnPrem-Hub-Conn"
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name
  type                = "Vnet2Vnet"
  routing_weight      = 1
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.TF_OnPremVPNGW.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.TF_HubVPNGW.id
  shared_key = var.VPNSiteToSiteSharedKey
  depends_on = [ azurerm_virtual_network_gateway.TF_HubVPNGW, azurerm_virtual_network_gateway.TF_OnPremVPNGW]

}

# VPN Connection between hub and on prem
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection

resource "azurerm_virtual_network_gateway_connection" "TF_HubOnPremConn" {
  name                = "Hub-OnPrem-Conn"
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name
  type                = "Vnet2Vnet"
  routing_weight      = 1
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.TF_HubVPNGW.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.TF_OnPremVPNGW.id
  shared_key = var.VPNSiteToSiteSharedKey
  depends_on = [ azurerm_virtual_network_gateway.TF_HubVPNGW, azurerm_virtual_network_gateway.TF_OnPremVPNGW]
}

