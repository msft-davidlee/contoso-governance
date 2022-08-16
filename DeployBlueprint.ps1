# Use this script to deploy Blueprint which will create the necessary resource groups in your environment
# and assigning the Contributor role to the Service principal in those resource groups.

# 1. Versioning is built into the script and you can add a switch to indicate a major or minor change.
# 2. Change notes is based on last git change log.

# Suggested Prefix convention first name initial, last name initial, workload type like platform which can be 
# abbreviated as pl and a number begin with 01. So, John Doe would be jdpla01 and you would manually 
# "increment" your last number. This is because services like Azure KeyVault which is soft-deleted cannot be 
# easily recreated quickly and you need a different unique name.
param(
    [Parameter(Mandatory = $true)][string]$BUILD_ENV,
    [Parameter(Mandatory = $true)][string]$PREFIX,
    [switch]$Major,
    [switch]$Minor)

   
$ErrorActionPreference = "Stop"

$spName = "GitHub"
$spList = az ad sp list --show-mine | ConvertFrom-Json
$result = $spList | Where-Object { $_.appDisplayName -eq $spName }
if ($result.Length -eq 0) {

    $subId = az account show --query id -o tsv

    # Minimally, we should assign a role so this SP is valid in this subscription.
    $result = az ad sp create-for-rbac -n $spName --scopes "/subscriptions/$subId" --role reader | ConvertFrom-Json
    if ($LastExitCode -ne 0) {
        throw "An error has occured. Unable to create service principal."
    }
}

$SVC_PRINCIPAL_ID = az ad sp show --id $result.appId --query id --output tsv
if ($LastExitCode -ne 0) {
    throw "An error has occured. Unable to get service principal object id."
}

$MY_PRINCIPAL_ID = az ad signed-in-user show --query id --output tsv
if ($LastExitCode -ne 0) {
    throw "An error has occured. Signed-in user query failed."
}

if (((az extension list | ConvertFrom-Json) | Where-Object { $_.name -eq "blueprint" }).Length -eq 0) {
    az extension add --upgrade -n blueprint    
}

$blueprintName = "contoso$BUILD_ENV"

$subscriptionId = (az account show --query id --output tsv)
if ($LastExitCode -ne 0) {
    throw "An error has occured. Subscription id query failed."
}

$deploymentSuffix = (Get-Date).ToString("yyyyMMddhhmmss") 
$outputs = (az deployment sub create --name "deploy-$blueprintName-$deploymentSuffix" --location 'centralus' --template-file blueprint.bicep `
        --subscription $subscriptionId `
        --parameters stackEnvironment=$BUILD_ENV svcPrincipalId=$SVC_PRINCIPAL_ID myPrincipalId=$MY_PRINCIPAL_ID `
        blueprintName=$blueprintName prefix=$PREFIX | ConvertFrom-Json)

if ($LastExitCode -ne 0) {
    throw "An error has occured. Deployment failed."
}

$msg = (git log --oneline -n 1)

$values = $outputs.properties.outputs.blueprints.value

foreach ($_ in $values) {
    $blueprintName = $_.name

    if ($blueprintName.Contains("contosodevshared") -and $BUILD_ENV -eq "dev") {
        Write-Host "Skipped $blueprintName"
        continue
    }

    Write-Host "Publishing $blueprintName"

    $versions = (az blueprint version list --blueprint-name $blueprintName | ConvertFrom-Json)
    if ($LastExitCode -ne 0) {
        throw "An error has occured. Version query failed for $blueprintName."
    }

    if (!$versions -or $versions.Length -eq 0) {
        $appliedVersion = '0.1'
    }
    else {
        $lastVersions = $versions[$versions.Length - 1].name.Split('.')
        $lastMajor = [int]$lastVersions[0]
        $lastMinor = [int]$lastVersions[1]

        if (!$Major -and !$Minor) {
            $lastMinor += 1
        }
        else {

            if ($Major) {
                $lastMajor += 1
            }

            if ($Minor) {
                $lastMinor += 1
            }
        }
        $appliedVersion = "$lastMajor.$lastMinor"
    }

    $blueprintJson = az blueprint publish --blueprint-name $blueprintName --version $appliedVersion --change-notes $msg --subscription $subscriptionId

    if ($LastExitCode -ne 0) {
        throw "An error has occured. Publish failed."
    }

    $blueprintId = ($blueprintJson | ConvertFrom-Json).id

    $assignmentName = "assign-$blueprintName-$appliedVersion"

    if ($BUILD_ENV -eq "dev") {
        if ($_.allResourcesDoNotDeleteInDev) {
            $lockMode = "AllResourcesDoNotDelete"
        }
        else {
            $lockMode = "None"
        }
    }
    else {
        $lockMode = "AllResourcesDoNotDelete"
    }
   

    az blueprint assignment create --subscription $subscriptionId --name $assignmentName `
        --location centralus --identity-type SystemAssigned --blueprint-version $blueprintId `
        --parameters "{}" --locks-mode $lockMode

    if ($LastExitCode -ne 0) {
        throw "An error has occured. Assignment failed."
    }

    az blueprint assignment wait --subscription $subscriptionId --name $assignmentName --created
    if ($LastExitCode -ne 0) {
        throw "An error has occured. Assignment failed (wait)."
    }
}

if ($BUILD_ENV -eq 'prod') {

    # This portion of the script handles the role assignments between the managed identities and shared resources.
    $ids = az identity list | ConvertFrom-Json
    if ($LastExitCode -ne 0) {
        throw "An error has occured. Identity listing failed."
    }

    $platformRes = (az resource list --tag stack-name='shared-key-vault' | ConvertFrom-Json)
    if (!$platformRes) {
        throw "Unable to find eligible platform resource!"
    }
    
    if ($platformRes.Length -eq 0) {
        throw "Unable to find 'ANY' eligible platform resource!"
    }
    
    # Platform specific Azure Key Vault as a Shared resource
    $akvid = ($platformRes | Where-Object { $_.type -eq 'Microsoft.KeyVault/vaults' -and $_.tags.'stack-environment' -eq $BUILD_ENV }).id
    
    $ids | ForEach-Object {
        $id = $_
        az role assignment create --assignee $id.principalId --role 'Key Vault Secrets User' --scope $akvid
        if ($LastExitCode -ne 0) {
            throw "An error has occured on role assignment."
        }
    }
}
