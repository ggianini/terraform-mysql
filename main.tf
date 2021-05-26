terraform {
  required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

resource "azurerm_resource_group" "rg-ggianini" {
  name     = "rg-ggianini"
  location = "eastus"

  tags = {
    "Environment" = "staging"
  }
}

resource "azurerm_virtual_network" "vn-ggianini" {
  name                = "vn-ggianini"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg-ggianini.name
}

resource "azurerm_subnet" "subnet-ggianini" {
  name                 = "subnet-ggianini"
  resource_group_name  = azurerm_resource_group.rg-ggianini.name
  virtual_network_name = azurerm_virtual_network.vn-ggianini.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "publicip-ggianini" {
  name                = "publicip-ggianini"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg-ggianini.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "nsg-ggianini" {
  name                = "nsg-ggianini"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg-ggianini.name

  security_rule {
    name                       = "ggianini-sql-rule"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ggianini-ssh-rule"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic-ggianini" {
  name                = "nic-ggianini"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg-ggianini.name

  ip_configuration {
    name                          = "niccfg-ggianini"
    subnet_id                     = azurerm_subnet.subnet-ggianini.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip-ggianini.id
  }
}

resource "azurerm_network_interface_security_group_association" "association-ggianini" {
  network_interface_id      = azurerm_network_interface.nic-ggianini.id
  network_security_group_id = azurerm_network_security_group.nsg-ggianini.id
}

data "azurerm_public_ip" "ggianini-public-ip" {
  name                = azurerm_public_ip.publicip-ggianini.name
  resource_group_name = azurerm_resource_group.rg-ggianini.name
}

resource "azurerm_storage_account" "saggianini" {
  name                     = "saggianini"
  resource_group_name      = azurerm_resource_group.rg-ggianini.name
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_virtual_machine" "vm-ggianini" {
  name                  = "vm-ggianini"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.rg-ggianini.name
  network_interface_ids = [azurerm_network_interface.nic-ggianini.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "Disk-ggianini"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }


  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.7"
    version   = "latest"
  }

  computer_name                   = "centOS-ggianini"
  admin_username                  = var.authvar.username
  admin_password                  = var.authvar.password
  disable_password_authentication = false

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.saggianini.primary_blob_endpoint
  }

  depends_on = [azurerm_resource_group.rg-ggianini]
}

output "public_ip_address_ggianini" {
  value = azurerm_public_ip.publicip-ggianini.ip_address
}

resource "null_resource" "mysql" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = var.authvar.username
      password = var.authvar.password
      host     = data.azurerm_public_ip.ggianini-public-ip.ip_address
    }
      script = "./bootstrap.sh"
  }
}
