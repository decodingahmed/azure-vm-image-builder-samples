# Resource schema definition for this resource can be found here:
#   https://learn.microsoft.com/en-us/azure/templates/microsoft.virtualmachineimages/imagetemplates?pivots=deployment-language-terraform
resource "azapi_resource" "builder" {
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2022-07-01"
  name      = "ImageBuilder"
  location  = azurerm_resource_group.builder.location
  parent_id = azurerm_resource_group.builder.id

  body = jsonencode({
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        "${azurerm_user_assigned_identity.builder.id}" = {}
      }
    }
    properties = {
      buildTimeoutInMinutes = 480
      vmProfile = {
        osDiskSizeGB           = 128
        vmSize                 = "Standard_D4s_v3"
        userAssignedIdentityId = [azurerm_user_assigned_identity.buildervm.id]
      }
      source = {
        type      = "PlatformImage"
        offer     = "Windows-11"
        publisher = "MicrosoftWindowsDesktop"
        sku       = "win11-23h2-pro"
        version   = "latest"
      }
      customize = [
        {
          type        = "PowerShell"
          name        = "Set environment variables"
          runElevated = true
          runAsSystem = true
          inline = [
            "[System.Environment]::SetEnvironmentVariable('MANAGED_IDENTITY_CLIENT_ID','${azurerm_user_assigned_identity.buildervm.client_id}', 'Machine')",
            "[System.Environment]::SetEnvironmentVariable('SOFTWARE_DOWNLOAD_URL','${data.azurerm_storage_blob.software.url}', 'Machine')",
          ]
        },
        {
          type        = "PowerShell"
          name        = "Download software from storage account"
          runElevated = true
          runAsSystem = true
          inline      = split("\n", file("${path.module}/scripts/Download-Software.ps1"))
        }
      ]

      distribute = [
      {
        type = "ManagedImage"
        artifactTags = {
          is_vhd      = "false"
        }
        runOutputName = "ManagedImageOutput"
        imageId       = "${azurerm_resource_group.builder.id}/providers/Microsoft.Compute/images/ImageWithPublicSoftware"
        location      = azurerm_resource_group.builder.location
      }
    ]
    }
  })
  depends_on = [
    azurerm_user_assigned_identity.builder,
    azurerm_role_assignment.builder,
    azurerm_user_assigned_identity.buildervm,
    azurerm_role_assignment.buildervmsoftware,
  ]
}

# Identity for the Image Builder
resource "azurerm_user_assigned_identity" "builder" {
  name                = "ImageBuilder-ManagedId"
  location            = azurerm_resource_group.builder.location
  resource_group_name = azurerm_resource_group.builder.name
  depends_on          = [azurerm_role_definition.builder]
}

# Permission to allow the Image Builder to create resources in the subscription
#   it needs to be able to create the staging VM + resources that will be generalised.
resource "azurerm_role_assignment" "builder" {
  scope                = data.azurerm_subscription.current.id
  principal_id         = azurerm_user_assigned_identity.builder.principal_id
  role_definition_name = azurerm_role_definition.builder.name
  depends_on           = [azurerm_role_definition.builder]
}

#
# Azure Image Builder Virtual Machine identity related resources
#

# Identity for the VM that gets created to run the customisation script
resource "azurerm_user_assigned_identity" "buildervm" {
  name                = "ImageBuilder-VM-ManagedId"
  location            = azurerm_resource_group.builder.location
  resource_group_name = azurerm_resource_group.builder.name
}

# Assignment to allow the VM profile customisation script to download from the 'software' storage account
resource "azurerm_role_assignment" "buildervmsoftware" {
  scope                = data.azurerm_storage_account.software.id
  principal_id         = azurerm_user_assigned_identity.buildervm.principal_id
  role_definition_name = "Storage Blob Data Reader"
}