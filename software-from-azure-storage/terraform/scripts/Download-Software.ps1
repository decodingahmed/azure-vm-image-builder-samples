$softwarePath = "C:\Software"

# Create directory if it doesn't already exist
if(-not (Test-Path -Path $softwarePath))
{
    New-Item -ItemType Directory -Force -Path $softwarePath
}

Write-Host("Starting download of MockTdf - StartTime: $(Get-Date)")

# Obtain access token for storage account access
$managedIdentityClientId = [Environment]::GetEnvironmentVariable("MANAGED_IDENTITY_CLIENT_ID")
Write-Host("Managed identity Client ID: $managedIdentityClientId")

$response = Invoke-WebRequest -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=$managedIdentityClientId&resource=https%3A%2F%2Fstorage.azure.com%2F" -Method GET -Headers @{Metadata = "true" } -UseBasicParsing
$content = $response.Content | ConvertFrom-Json
$accessToken = $content.access_token

# Storage account location from environment variable
# Create the destination
$storageBlobURL = [Environment]::GetEnvironmentVariable('SOFTWARE_DOWNLOAD_URL')
$downloadPath = "$softwarePath\$(Split-Path -Path $storageBlobURL -Leaf)"

# Downloading software from storage account
Write-Host ("Downloading software from '$storageBlobURL' to location '$downloadPath' - StartTime: $(Get-Date)")
$elapsedTime = Measure-Command {
    $wc = New-Object System.Net.WebClient
    $wc.Headers['Authorization'] = "Bearer $accessToken"
    $wc.Headers['x-ms-version'] = '2017-11-09'
    $wc.DownloadFile($storageBlobURL, $downloadPath)
}

Write-Host ("Download complete in $($elapsedTime.TotalSeconds) seconds - EndTime: $(Get-Date).")