provider "azurerm" {

}

terraform {
  backend "azurerm" {
    resource_group_name = "jambitiac"
    storage_account_name = "jambitiac"
    container_name       = "tfstate"
    key = "mh.terraform.tfstate"
  }
}

resource "azurerm_resource_group" "sample_app" {
  name     = "rg_mh_sample_app"
  location = "westeurope"
  tags {
    enviornment = "Produktion"
  }
}

#Assume that custom image has been already created in the 'jambitiac' resource group
data "azurerm_resource_group" "image" {
  name = "jambitiac"
}

data "azurerm_image" "image" {
  name                = "mh-1524574619"
  resource_group_name = "${data.azurerm_resource_group.image.name}"
}

resource "azurerm_public_ip" "test" {
  name                         = "test_pip"
  location                     = "${azurerm_resource_group.sample_app.location}"
  resource_group_name          = "${azurerm_resource_group.sample_app.name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30
}

resource "azurerm_virtual_network" "test" {
  name                = "acctvn"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.sample_app.location}"
  resource_group_name = "${azurerm_resource_group.sample_app.name}"
}

resource "azurerm_subnet" "test" {
  name                 = "acctsub"
  resource_group_name  = "${azurerm_resource_group.sample_app.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "test" {
  name                = "acctni"
  location            = "${azurerm_resource_group.sample_app.location}"
  resource_group_name = "${azurerm_resource_group.sample_app.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.2.5"
    public_ip_address_id          = "${azurerm_public_ip.test.id}"
  }
}

resource "azurerm_virtual_machine" "test" {
  name                  = "acctvm"
  location              = "${azurerm_resource_group.sample_app.location}"
  resource_group_name   = "${azurerm_resource_group.sample_app.name}"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size               = "Standard_A0"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  storage_image_reference {
    id="${data.azurerm_image.image.id}"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${data.azurerm_image.image.name}"
    admin_username = "jambitadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
