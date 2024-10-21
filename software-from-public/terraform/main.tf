terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.82.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.12.0"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

provider "azapi" {
}

data "azurerm_subscription" "current" {
}

resource "azurerm_resource_group" "builder" {
  name     = "ImageBuilder-Public-Software-rg"
  location = "uksouth"
}

# A custom role definition for Azure Image Builder
resource "azurerm_role_definition" "builder" {
  name        = "AzureImageBuilderRole"
  scope       = data.azurerm_subscription.current.id
  description = "Role that defines the permissions an Azure Image Builder resource has to build Custom VM Images in a given subscription."
  assignable_scopes = [
    azurerm_resource_group.builder.id,
    data.azurerm_subscription.current.id
  ]
  permissions {
    actions = [
      "Microsoft.Compute/galleries/read",
      "Microsoft.Compute/galleries/images/read",
      "Microsoft.Compute/galleries/images/versions/read",
      "Microsoft.Compute/galleries/images/versions/write",
      "Microsoft.Compute/images/write",
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/images/delete",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action"
    ]
  }
}
