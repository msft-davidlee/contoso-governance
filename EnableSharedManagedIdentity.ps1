$ErrorActionPreference = "Stop"
    
$kv = (az resource list --tag ard-resource-id=shared-key-vault | ConvertFrom-Json)
if ($LastExitCode -ne 0) {
    throw "An error has occured. Unable to locate key vault."
}

if (!$kv) {
    throw "Unable to find eligible shared key vault resource!"
}

$sharedResourceGroup = $kv.resourceGroup

$mid = (az identity list -g $sharedResourceGroup | ConvertFrom-Json)
if ($LastExitCode -ne 0) {
    throw "An error has occured. An error occured when getting managed identity from rg."
}

if (!$mid) {
    Write-Host "Managed identity does not exist. Creating one now..."

    $miName = "shared-managed-identity"
    # Perform role assignment
    $mid = az identity create --name $miName --resource-group $sharedResourceGroup --tags ard-resource-id=$miName | ConvertFrom-Json

    az role assignment create --assignee-object-id $mid.principalId --role "Key Vault Secrets User" `
        --scope $kv.id --assignee-principal-type ServicePrincipal

    if ($LastExitCode -ne 0) {        
        throw "An error has occured. Unable to create $miName."
    }
}

$aksGroups = az group list --tag ard-solution-id=aks-demo | ConvertFrom-Json  
$aksGroups | ForEach-Object {
    $scope = $_.id
    az role assignment create --assignee $mid.principalId --role "Contributor" --scope $scope
    if ($LastExitCode -ne 0) {        
        throw "An error has occured. Unable to create assignment to $scope."
    }
}
