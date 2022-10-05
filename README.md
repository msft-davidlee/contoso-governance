# Disclaimer
The information contained in this README.md file and any accompanying materials (including, but not limited to, scripts, sample codes, etc.) are provided "AS-IS" and "WITH ALL FAULTS." Any estimated pricing information is provided solely for demonstration purposes and does not represent final pricing and Microsoft assumes no liability arising from your use of the information. Microsoft makes NO GUARANTEES OR WARRANTIES OF ANY KIND, WHETHER EXPRESSED OR IMPLIED, in providing this information, including any pricing information.

# Introduction
This project demostrates the use of Azure Resource Discovery to manage resource groups and specific resource so that we can easily lookup during code deployment. 

For managing multiple Azure Subscriptions, refer to [Azure Landing Zone](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/).

## Tagging Standards
1. All resource groups and resources will have a tag of mgmt-id which represents the management id. This is hardcoded to be contoso and indicates that these are specifically managed by this blueprint in this repo we are executing here.
2. All resource groups and resources will have a tag of stack-name which represents the type of workload it belongs to. We have several demos such as App Services and AKS.
3. All resource groups and resources will have a tag of stack-environment which represents the type of environment such as dev or prod. These are the only 2 values we have.

## Naming convention for Prefix for resources naming
First, you don't get to manually name your resources. We will establish a naming convention using a prefix and a number. This naming convention has to generate a unique resource name. Note that we should adhere to the lowest common denominator of naming conventions of storage account which also requires a max length of 24 characters. However, we would also like to keep this as short as possible so we can extend on the naming convention if we need to - within the bicep file.

Suggested Prefix convention first name initial, last name initial, workload type like pla and a number begin with 01 So, John Doe would be jdpla01 and you would manually "increment" your last number. This is because services like Azure KeyVault which is soft-deleted cannot be easily recreated quickly and you need a different unique name. Notice that we have a max length of 7 for this prefix but we will also append either dev or prod to the name which makes it either 10 chars or 11 chars. Again, we strive to keep it short.

# Get Started

We will be using GitHub as our code repository so we will create a Service Principal named GitHub in AAD so we can assign this SP the role of Contributor in each of the Resource Group so it can create resources. You will use your Principal Id so we can assign you rights to shared resources such as Azure Key Vault. Note that you need to have rights for role assignments in your Subscription.

Use the following command in your local Azure CLI or CloudShell to run the Azure Blueprint deployment. One important note about this script is that it is idempotent. It means it can be executed as many times as we like and the results would be the same. This is the reason why the prefix is only configured once when this scripts runs the first time and is reused.

```
.\DeployBlueprint.ps1 -BUILD_ENV <Env either prod or dev> -PREFIX <See naming convention below>
```

If you need to rollback all blueprint deployments, run the following command.

```
 .\RollbackBlueprint.ps1
```

If you need to remove resource groups after removing the blueprints, run the following command
```
 .\RemoveSharedResources.ps1 -BUILD_ENV <Env either prod or dev> 
```
## Cloud Shell
Once you have deployed the dev and prod Azure Blueprints in your Azure Subscription, there will be a personal resource group which contains a storage account where you can associate your Cloud Shell with. 

![Create Cloud Shell](/docs/CreateCloudShell.png)

Be sure to use existing storage account which has been created for you.

![Use existing storage](/docs/UseExisting.png)

## Have an issue?
You are welcome to create an issue if you need help but please note that there is no timeline to answer or resolve any issues you have with the contents of this project. Use the contents of this project at your own risk! If you are interested to volunteer to maintain this, please feel free to reach out to be added as a contributor and send Pull Requests (PR).
