$subscriptionId = (az account show --query id --output tsv)
if ($LastExitCode -ne 0) {
    throw "An error has occured. Subscription id query failed."
}

$list = az blueprint assignment list --subscription $subscriptionId | ConvertFrom-Json
$list | ForEach-Object {
    $name = $_.name
    az blueprint assignment delete --name $name --subscription $subscriptionId --yes  
    if ($LastExitCode -ne 0) {
        throw "An error has occured. Rollback assignment $name failed."
    }
}

$blueprints = az blueprint list  --subscription $subscriptionId | ConvertFrom-Json
if ($LastExitCode -ne 0) {
    throw "An error has occured. Listing all blueprints failed."
}

$blueprints | ForEach-Object {
    $name = $_.name
    $versions = az blueprint version list --blueprint-name $name --subscription $subscriptionId | ConvertFrom-Json
    if ($LastExitCode -ne 0) {
        throw "An error has occured. Listing all versions for $name failed."
    }
    $versions | ForEach-Object {
        $version = $_.name
        az blueprint version delete --blueprint-name $name --subscription $subscriptionId --version $version --yes
        if ($LastExitCode -ne 0) {
            throw "An error has occured. Rollbacking back version $version failed."
        }
    }

    az blueprint delete --name $name --subscription $subscriptionId --yes
    if ($LastExitCode -ne 0) {
        throw "An error has occured. Removing blueprint $name failed."
    }
}