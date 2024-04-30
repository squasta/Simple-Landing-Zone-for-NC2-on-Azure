

# An Azure public for Azure Bastion
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
resource "azurerm_public_ip" "TF_bastion_public_ip" {
  count               = var.EnableAzureBastion
  name                = var.PublicBastionIPName
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


# An Azure Bastion Host
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/bastion_host
# Azure Bastion SKU https://learn.microsoft.com/en-us/azure/bastion/configuration-settings 
resource "azurerm_bastion_host" "TF_bastion_host" {
  count               = var.EnableAzureBastion
  name                = var.AzureBastionHostName
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name
  sku                 = "Basic"    # Developper SKU is still in preview but will be cheaper
  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.TF_Azure_Bastion_Subnet.id
    public_ip_address_id = azurerm_public_ip.TF_bastion_public_ip[0].id
  }
}

# A Network Interface for Azure Windows VM
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
resource "azurerm_network_interface" "TF_VM_Jumbox_Nic" {
  count               = var.EnableJumboxVM
  name                = var.VMBastionNicName
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.TF_Fgw_External_Subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


# A Windows Virtual Machine for Bastion
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine
resource "azurerm_windows_virtual_machine" "TF_VM_Jumbox" {
  count                 = var.EnableJumboxVM
  name                  = var.VMJumpboxName
  resource_group_name   = azurerm_resource_group.TF_RG.name
  location              = azurerm_resource_group.TF_RG.location
  size                  = var.AzureVMSize    # B2ms or greater is better for good experience
  admin_username        = var.AdminUsername
  admin_password        = var.AdminPassword
  network_interface_ids = [azurerm_network_interface.TF_VM_Jumbox_Nic[0].id]
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
  computer_name = var.HostnameVMJumbox
  provision_vm_agent = true
  enable_automatic_updates = true
  timezone = "W. Europe Standard Time"
  tags = {
    usage = "Jumpbox with Azure Bastion"
  }
}
