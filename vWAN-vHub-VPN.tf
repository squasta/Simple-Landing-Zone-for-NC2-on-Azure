
# The virtualWAN resource represents a virtual overlay of your Azure network and is a collection of multiple resources.
# It contains links to all your virtual hubs that you would like to have within the virtual WAN
# and also contains links to all the VPN sites that you would like to have within the virtual WAN.
# cf. https://learn.microsoft.com/en-us/azure/virtual-wan/virtual-wan-about
resource "azurerm_virtual_wan" "TF_Vwan" {
  name                = "NC2-virtualwan"
  resource_group_name = azurerm_resource_group.TF_RG.name
  location            = azurerm_resource_group.TF_RG.location
}

## Virtual WAN vHub
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_wan_vhub
# A virtual hub is a Microsoft-managed virtual network.
# The hub contains various service endpoints to enable connectivity. 
# From your on-premises network (vpnsite), you can connect to a VPN gateway inside the virtual hub, 
# connect ExpressRoute circuits to a virtual hub, or even connect mobile users to a point-to-site gateway
# in the virtual hub
# The hub is the core of your network in a region
resource "azurerm_virtual_hub" "TF_Vhub" {
  name                = "NC2-virtualhub"
  resource_group_name = azurerm_resource_group.TF_RG.name
  location            = azurerm_resource_group.TF_RG.location
  virtual_wan_id      = azurerm_virtual_wan.TF_Vwan.id
  address_prefix      = "172.16.0.0/16"
  sku                = "Basic"    # can be Basic or Standard. Basic is enough for testing with Site-to-Site VPN 
                                  # cf. https://learn.microsoft.com/en-us/azure/virtual-wan/virtual-wan-about#basicstandard
}

## Virtual Hub Connection with Cluster management VNet
# The hub virtual network connection resource is used to connect the hub seamlessly to your virtual network.
# One virtual network can be connected to only one virtual hub.
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_hub_connection

resource "azurerm_virtual_hub_connection" "TF_VhubConn_ClusterMgmt" {
  name                      = "VHubConn-ClusterMgmt"
  virtual_hub_id            = azurerm_virtual_hub.TF_Vhub.id
  remote_virtual_network_id = azurerm_virtual_network.TF_Cluster_VNet.id
}


## Virtual Hub Connection with PC VNet
# The hub virtual network connection resource is used to connect the hub seamlessly to your virtual network.
# One virtual network can be connected to only one virtual hub.
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_hub_connection

resource "azurerm_virtual_hub_connection" "TF_VhubConn_PC" {
  name                      = "VHubConn-ClusterMgmt"
  virtual_hub_id            = azurerm_virtual_hub.TF_Vhub.id
  remote_virtual_network_id = azurerm_virtual_network.TF_PC_VNet.id
}


## Virtual WAN site to site gateway
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vpn_gateway
resource "azurerm_vpn_gateway" "TF_VPNGW_Vhub" {
  name                = "VPNGW-NC2-virtualhub"
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name
  virtual_hub_id      = azurerm_virtual_hub.TF_Vhub.id
  scale_unit          = 1
}



## Virtual WAN VPN Site
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_wan_vpn_site
# Site: This resource is used for site-to-site connections only. The site resource is vpnsite. 
# It represents your on-premises VPN device and its settings.
# The site resource is used to configure the on-premises VPN device to connect to the virtual hub.
# cf. https://learn.microsoft.com/en-us/azure/virtual-wan/virtual-wan-site-to-site-portal 

# resource "azurerm_virtual_wan_vpn_site" "TF_VpnSite" {
#   name                = "NC2-vpnSite"
#   resource_group_name = azurerm_resource_group.TF_RG.name
#   location            = azurerm_resource_group.TF_RG.location
#   virtual_wan_id      = azurerm_virtual_wan.TF_Vwan.id
#   address_space       = ["192.168.250.0/24"]
#     is_security_site    = false
#     vpn_site_links {
#     name = "NC2-vpnSiteLink"
#     virtual_hub_id = azurerm_virtual_hub.TF_Vhub.id
#     vpn_device_ip_address = "8.8.8.8"   # external public IP
#     vpn_device_vendor = "Cisco"
#     vpn_device_model = "ASA 5505"
#     vpn_device_fqdn = "vpn.contoso.com"
#     shared_key = "abc123"
#     }
# }
