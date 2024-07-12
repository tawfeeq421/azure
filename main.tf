resource "azurerm_resource_group" "myresourcegroup" {
  name     = "terraform"
  location = "East US"
}

resource "azurerm_virtual_network" "mynetwork" {
  name                = "terraform-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myresourcegroup.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "internal-sub"
  virtual_network_name = azurerm_virtual_network.mynetwork.name
  resource_group_name  = azurerm_resource_group.myresourcegroup.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "mypublicip" {
  name                = "terra-ip"
  location            = azurerm_resource_group.myresourcegroup.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "net_interface" {
  name                = "net-int"
  location            = azurerm_resource_group.myresourcegroup.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name
  ip_configuration {
    name                          = "internal1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mypublicip.id
  }
}

resource "azurerm_linux_virtual_machine" "terraform_vm" {
  name                  = "terra-vm"
  resource_group_name   = azurerm_resource_group.myresourcegroup.name
  location              = azurerm_resource_group.myresourcegroup.location
  size                  = "Standard_F2"
  admin_username        = "tawfeeq"
  network_interface_ids = [azurerm_network_interface.net_interface.id]

  admin_ssh_key {
    username   = "tawfeeq"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
