# Azure VM Image Builder — Software from Azure Storage

This sample demonstrates how to use Azure VM Image Builder to create a custom VM image where the software installers are downloaded from a private Azure Storage account during the build process.

## How it differs from the public software sample

| Aspect | Public Software | Azure Storage |
|--------|----------------|---------------|
| Software source | Downloaded directly from the internet | Downloaded from a private Azure Blob Storage account |
| Authentication | None required | Managed Identity with `Storage Blob Data Reader` role |
| Additional identity | N/A | A dedicated VM identity (`buildervm`) is assigned to the image template VM profile |
| Customization steps | Install script only | Set environment variables → Download from storage → Install |

The key additions are:

### VM identity and Role Assignment for storage access

A dedicated managed identity is created, assigned to the image template's VM profile, and granted `Storage Blob Data Reader` on the storage account. This allows the staging VM to authenticate against Azure Storage:

```hcl
resource "azurerm_user_assigned_identity" "buildervm" {
  name                = "ImageBuilder-VM-ManagedId"
  location            = azurerm_resource_group.builder.location
  resource_group_name = azurerm_resource_group.builder.name
}

resource "azurerm_role_assignment" "software" {
  scope                = data.azurerm_storage_account.software.id
  principal_id         = azurerm_user_assigned_identity.buildervm.principal_id
  role_definition_name = "Storage Blob Data Reader"
}
```

### Identity attached to the VM profile

The identity is added to the image template's `vmProfile` so the staging VM can use it:

```hcl
resource "azapi_resource" "builder" {
  ...
  body = jsonencode({
    ...
    properties = {
      ...
      vmProfile = {
        ...
        userAssignedIdentityId = [azurerm_user_assigned_identity.buildervm.id]
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
        },
        ...
      ]
    }
  })
}
```

### Download script

`Download-Software.ps1` uses the managed identity to obtain an access token and download the software zip from storage:

```powershell
$response = Invoke-WebRequest -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=$managedIdentityClientId&resource=https%3A%2F%2Fstorage.azure.com%2F" `
  -Method GET -Headers @{Metadata = "true"} -UseBasicParsing
$accessToken = ($response.Content | ConvertFrom-Json).access_token

$wc = New-Object System.Net.WebClient
$wc.Headers['Authorization'] = "Bearer $accessToken"
$wc.DownloadFile($storageBlobURL, $downloadPath)
```

## Prerequisites

This sample expects the following resources to already exist **before** running `terraform apply`:

1. **Resource Group** — `ImageBuilder-AzureStorage-Software-rg`
2. **Storage Account** — `softwarestg` within the above resource group
3. **Blob Container** — `installers` within the storage account
4. **Blob** — `software.zip` uploaded into the `installers` container

These are referenced as Terraform `data` sources and will fail at plan time if they are not already in place.