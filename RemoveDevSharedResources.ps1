$groups = az group list | ConvertFrom-Json
$grp = $groups | Where-Object { $_.tags.'stack-environment' -eq "dev" }
$grp | ForEach-Object {
    $name = $_.name
    az group delete --name $name --yes
}
