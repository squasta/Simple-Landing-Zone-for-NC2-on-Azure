

## a Windows Server 2022 VM connected to the On-Premises network
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine

resource "azurerm_windows_virtual_machine" "TF_VM4testingNetwork_OnPremises" {
  count                 = var.EnableVM4testingNetwork_OnPremises
  name                  = "VMonPremises"
  resource_group_name   = azurerm_resource_group.TF_RG.name
  location              = azurerm_resource_group.TF_RG.location
  size                  = var.AzureVMSize    # B2ms or greater is better for good experience
  admin_username        = var.AdminUsername
  admin_password        = var.AdminPassword
  network_interface_ids = [azurerm_network_interface.TF_VM4testingNetwork_OnPremises_Nic[0].id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  computer_name = "VMonPremises"
  provision_vm_agent = true
  timezone = "UTC"

}


## Network interface for VM on Premises
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface

resource "azurerm_network_interface" "TF_VM4testingNetwork_OnPremises_Nic" {
  count               = var.EnableVM4testingNetwork_OnPremises
  name                = "VMonPremises-Nic"
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.TF_OnPremSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}