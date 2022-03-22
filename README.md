# Disclaimer
The information contained in this README.md file and any accompanying materials (including, but not limited to, scripts, sample codes, etc.) are provided "AS-IS" and "WITH ALL FAULTS." Any estimated pricing information is provided solely for demonstration purposes and does not represent final pricing and Microsoft assumes no liability arising from your use of the information. Microsoft makes NO GUARANTEES OR WARRANTIES OF ANY KIND, WHETHER EXPRESSED OR IMPLIED, in providing this information, including any pricing information.

# Introduction
This project demostrates the use of Azure Blueprint to manage resource groups, managed identities and use of role assignments to a shared Azure Key Vault resource.

We will be using GitHub as our code repository so you should create a Service Principal in AAD so we can assign this SP the role of Contributor in each of the Resource Group so it can create resources. You should also pass in your Principal Id so we can assign you rights to shared resources such as Azure Key Vault. Note that you need to have rights for role assignments in your Subscription.

Use the following command in your local Azure CLI or CloudShell to run the Azure Blueprint deployment.

```
.\DeployBlueprint.ps1 -BUILD_ENV prod -SVC_PRINCIPAL_ID <GitHub Service Principal> -MY_PRINCIPAL_ID <Your Service Principal Id> -PREFIX <See naming convention below>
```

If you need to rollback, run the following command.

```
 .\RollbackBlueprint.ps1
```

## Naming convention for Prefix
Suggested Prefix convention first name initial, last name initial, workload type like pla and a number begin with 01 So, John Doe would be jdpla01 and you would manually "increment" your last number. This is because services like Azure KeyVault which is soft-deleted cannot be easily recreated quickly and you need a different unique name.

# Get Started

## Have an issue?
You are welcome to create an issue if you need help but please note that there is no timeline to answer or resolve any issues you have with the contents of this project. Use the contents of this project at your own risk! If you are interested to volunteer to maintain this, please feel free to reach out to be added as a contributor and send Pull Requests (PR).
