$groups = az group list --tag stack-sub-name=shared-services | ConvertFrom-Json
$grp = $groups | Where-Object { $_.tags.'stack-environment' -eq "dev" }

az group delete --name $grp.name --yes