terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.43.0"
    }
  }

}

provider "azurerm" {
  
    subscription_id = "ea6e6692-4d05-4c5b-9909-51c7dc5f5c2b"
    client_id       = "d8a08696-446d-4926-a979-a2a871833c0a"
    client_secret   = "Test123456."
    tenant_id       = "4dfdfd67-3a37-4e2e-b9f0-434c7061ba33"
    
    features {
      
    }
}


resource "azurerm_resource_group" "abdulwahab-project" {
  name     = "abdulwahab-project"
  location = "West Europe"
}

resource "azurerm_ssh_public_key" "sshkey" {
  name                = "abdulwahab"
  location            = "West Europe"
  resource_group_name = "abdulwahab-project"
  public_key          = file("./sshkey.pub")
}
resource "azurerm_virtual_network" "abdulwahab-project" {
  name                = "abdulwahab-project-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.abdulwahab-project.location
  resource_group_name = azurerm_resource_group.abdulwahab-project.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = "abdulwahab-project"
  virtual_network_name = "abdulwahab-project-network"
  address_prefixes     = ["10.0.2.0/24"]
}


#vm1
resource "azurerm_network_security_group" "jenkins-vm-nsg" {
  name                = "jenkins-vm-nsg"
  location            = "West Europe"
  resource_group_name = "abdulwahab-project"

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "all_out"
    priority                   = 400
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jenkins-association" {
  network_interface_id      = azurerm_network_interface.abdulwahab-project-nic1.id
  network_security_group_id = azurerm_network_security_group.jenkins-vm-nsg.id
}


resource "azurerm_public_ip" "jenkins-vm-public_ip" {
  name                = "jenkins-vm-public_ip"
  resource_group_name = "abdulwahab-project"
  location            = "West Europe"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "abdulwahab-project-nic1" {
  name                = "abdulwahab-project-nic1"
  location            = "West Europe"
  resource_group_name = "abdulwahab-project"

  ip_configuration {
    name                          = "jenkins-vm-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.jenkins-vm-public_ip.id
  }
}


resource "azurerm_linux_virtual_machine" "jenkins-vm" {
  name                = "jenkins-vm"
  resource_group_name = "abdulwahab-project"
  location            = "West Europe"
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "Test123456."
  
  network_interface_ids = [azurerm_network_interface.abdulwahab-project-nic1.id]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }


  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_ssh_public_key.sshkey.public_key
  }
}

#vm2

resource "azurerm_network_security_group" "server-vm-nsg" {
  name                = "server-vm-nsg"
  location            = "West Europe"
  resource_group_name = "abdulwahab-project"

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "all_out"
    priority                   = 400
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "server-association" {
  network_interface_id      = azurerm_network_interface.abdulwahab-project-nic2.id
  network_security_group_id = azurerm_network_security_group.server-vm-nsg.id
}

resource "azurerm_public_ip" "server-vm-public_ip" {
  name                = "server-vm-public_ip"
  resource_group_name = "abdulwahab-project"
  location            = "West Europe"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "abdulwahab-project-nic2" {
  name                = "abdulwahab-project-nic2"
  location            = "West Europe"
  resource_group_name = "abdulwahab-project"

  ip_configuration {
    name                          = "server-vm-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.server-vm-public_ip.id
  }
}


resource "azurerm_linux_virtual_machine" "server-vm" {
  name                = "server-vm"
  resource_group_name = "abdulwahab-project"
  location            = "West Europe"
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  admin_password      = "Test123456."
  
  network_interface_ids = [azurerm_network_interface.abdulwahab-project-nic2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_ssh_public_key.sshkey.public_key
  }
}

