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

resource "azurerm_availability_set" "test" {
  name                = "acceptanceTestAvailabilitySet1"
  location            = "${azurerm_resource_group.sample_app.location}"
  resource_group_name = "${azurerm_resource_group.sample_app.name}"
  managed             = true
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
  count                        = "${var.sample-app-count}"
  name                         = "pip-${count.index}"
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
  count               = "${var.sample-app-count}"
  name                = "acctni-${count.index}"
  location            = "${azurerm_resource_group.sample_app.location}"
  resource_group_name = "${azurerm_resource_group.sample_app.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.test.*.id[count.index]}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.test.id}"]
  }
}

resource "azurerm_network_security_group" "test" {
  name                  = "nsg_test"
  location              = "${azurerm_resource_group.sample_app.location}"
  resource_group_name   = "${azurerm_resource_group.sample_app.name}"
}

resource "azurerm_network_security_rule" "test" {
  name                       = "port8080"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8080"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name        = "${azurerm_resource_group.sample_app.name}"
  network_security_group_name = "${azurerm_network_security_group.test.name}"
}

resource "azurerm_virtual_machine" "test" {
  count                 = "${var.sample-app-count}"
  name                  = "acctvm-${count.index}"
  location              = "${azurerm_resource_group.sample_app.location}"
  resource_group_name   = "${azurerm_resource_group.sample_app.name}"
  network_interface_ids = ["${azurerm_network_interface.test.*.id[count.index]}"]
  vm_size               = "Standard_A0"
  availability_set_id   = "${azurerm_availability_set.test.id}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  storage_image_reference {
    id="${data.azurerm_image.image.id}"
  }

  storage_os_disk {
    name              = "myosdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${data.azurerm_image.image.name}-${count.index}"
    admin_username = "jambitadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}



resource "azurerm_public_ip" "lbPip" {
  name                          = "PublicIPForLB"
  location                      = "${azurerm_resource_group.sample_app.location}"
  resource_group_name           = "${azurerm_resource_group.sample_app.name}"
  public_ip_address_allocation  = "Dynamic"
  idle_timeout_in_minutes      = 30
}

resource "azurerm_lb" "test" {
  name                  = "lb"
  location              = "${azurerm_resource_group.sample_app.location}"
  resource_group_name   = "${azurerm_resource_group.sample_app.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.lbPip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "test" {
  resource_group_name = "${azurerm_resource_group.sample_app.name}"
  loadbalancer_id     = "${azurerm_lb.test.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_rule" "test" {
  resource_group_name            = "${azurerm_resource_group.sample_app.name}"
  loadbalancer_id                = "${azurerm_lb.test.id}"
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.test.id}"
  probe_id                       = "${azurerm_lb_probe.test.id}"
}

resource "azurerm_lb_probe" "test" {
  name                = "lb_probe-vm1"
  resource_group_name = "${azurerm_resource_group.sample_app.name}"
  loadbalancer_id     = "${azurerm_lb.test.id}"
  protocol            = "tcp"
  port                = "8080"
  interval_in_seconds = "15"
  number_of_probes    = "3"
}
