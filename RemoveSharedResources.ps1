param([Parameter(Mandatory = $true)][string]$BUILD_ENV)
$groups = az group list | ConvertFrom-Json
$grp = $groups | Where-Object { $_.tags.'stack-environment' -eq $BUILD_ENV -and $_.tags.'mgmt-id' -eq "contoso" }
$grp | ForEach-Object {
    $name = $_.name
    az group delete --name $name --yes
}
