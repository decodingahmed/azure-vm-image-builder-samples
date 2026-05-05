#
# Software Storage Configuration
#

# For this sample to work, the software storage account needs to exist with 
# "installers" blob container and "software.zip" file uploaded into it

data "azurerm_storage_account" "software" {
  name                = "softwarestg"
  resource_group_name = "ImageBuilder-AzureStorage-Software-rg"
}

data "azurerm_storage_blob" "software" {
  name                   = "software.zip"
  storage_account_name   = data.azurerm_storage_account.software.name
  storage_container_name = "installers"
}