$setupPath = "C:\Setup"

if (-not (Test-Path -Path $setupPath)) {
    New-Item -ItemType Directory -Force -Path $setupPath
}

$drawioInstallerPath = "$setupPath\draw.io-22.1.2-windows-installer.exe"

Write-Host ("Downloading Draw.io to location '$drawioInstallerPath'")
Invoke-WebRequest -Uri "https://github.com/jgraph/drawio-desktop/releases/download/v22.1.2/draw.io-22.1.2-windows-installer.exe" -OutFile "$drawioInstallerPath"
Write-Host ("Download complete.")

Write-Host ("Installing Draw.io.")
Start-Process "$drawioInstallerPath" -ArgumentList /S -NoNewWindow -Wait
Write-Host ("Installation complete.")

Remove-Item -Path $drawioInstallerPath -Force