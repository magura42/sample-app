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
