$ErrorActionPreference = "Stop"
    
# This is the rg where the application should be deployed
$groups = az group list --tag ard-environment=prod | ConvertFrom-Json
$appResourceGroup = ($groups | Where-Object { $_.tags.'ard-solution-id' -eq 'shared-services' }).name
Write-Host "::set-output name=appResourceGroup::$appResourceGroup"

$personalResourceGroup = ($groups | Where-Object { $_.tags.'ard-solution-id' -eq 'personal' }).name
Write-Host "::set-output name=personalResourceGroup::$personalResourceGroup"
