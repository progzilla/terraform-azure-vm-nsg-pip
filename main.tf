# provider definition
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.84.0"
    }
  }
}

# create remote state storage into azure storage
# terraform {
#   backend "azurerm" {
#     resource_group_name   = "rg-TerraformPlay"
#     storage_account_name  = "terraform-storage"
#     container_name        = "tfstate"
#     key                   = "terraform.state"
#   }
# }

# try var.location != "" ? var.location : "uksouth" 

# create remote state storage into terraform cloud
terraform {
  backend "remote" {
    organization = "My Company"

    workspaces {
      name = ""
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {
    #
  }
}
# create resource group
resource "azurerm_resource_group" "rg" {
  name = "rg-TerraformPlay"
  location = "uksouth" 
  tags = {
    "Env" = "Dev"
  }
}

# create virtual network
resource "azurerm_virtual_network" "vnet" {
  name = "rg-TerraVnet"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = [ "10.0.0.0/16" ]
}

# create subnet
resource "azurerm_subnet" "subnet" {
  name = "snet-dev-uksouth-001"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.0.0/24"]
}

# create Public IP

resource "azurerm_public_ip" "publicip" {
  name = "pip-vnetterraform-dev-uksouth-001"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
}

# create network security group and rule

resource "azurerm_network_security_group" "nsg" {
  name = "nsg-terraform-001"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name = "SSH"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

# create networt interface
resource "azurerm_network_interface" "nic" {
  name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                = "niccfg-vmterraforrm"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = azurerm_public_ip.publicip.id
  }
}

# create virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name = "terraform-linux-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  size = "Standard_F2"
  admin_username = "azadminuser"
  admin_password = "P@sswrd!234"
  disable_password_authentication = false
  network_interface_ids = [ 
      azurerm_network_interface.nic.id, 
    ]
    # admin_ssh_key {
    #   username = "azadminuser"
    #   // public_key = file("~/.ssh/id_rsa.pub")
      
    # }

    os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    }

    source_image_reference {
      publisher = "Canonical"
      offer = "UbuntuServer"
      sku = "16.04-LTS"
      version = "latest"
    }
}

output "pip" {
  value = azurerm_public_ip.publicip.ip_address
}

