# Single one-time script to export existing resources from shared-services folder.
# Keeping this script for reference only.

$o = az group export --name shared-services -g shared-services -o json
Set-Content temp.json -Value $o
az bicep decompile --file .\temp.json --force
Remove-Item .\temp.json -Force
Move-Item .\temp.bicep .\Deployment\shared-services.bicep -Force