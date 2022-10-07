# Contoso Governance

## Disclaimer

The information contained in this README.md file and any accompanying materials (including, but not limited to, scripts, sample codes, etc.) are provided "AS-IS" and "WITH ALL FAULTS." Any estimated pricing information is provided solely for demonstration purposes and does not represent final pricing and Microsoft assumes no liability arising from your use of the information. Microsoft makes NO GUARANTEES OR WARRANTIES OF ANY KIND, WHETHER EXPRESSED OR IMPLIED, in providing this information, including any pricing information.

## Introduction

Welcome to the landing page for all contoso-`*` respos located in the msft-davidlee organization. This repo is specifically used to create all dependent resources so that we can create those workloads. We are making use of the idea of [Azure Resource Discovery or ARD](https://github.com/msft-davidlee/azure-resource-discovery) to manage resource groups and specific resource tagging so that we can easily lookup dependent resources during code deployment against those workloads. Refer to the manifest.json file for more information on the resource groups we are creating. Please note that everything we demo around the contoso-`*` revolves around a single Azure Subscription.

Note that this setup we have here is because we are have created several different types of workloads for the purpose of demonstrating Azure capabilities and we are specifically targeting a single Azure Subscription. For governance around multiple Azure Subscriptions, please refer to [Azure Landing Zone](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/).

## Get Started

1. [Fork this git repo](https://docs.github.com/en/get-started/quickstart/fork-a-repo)
2. Clone this repo locally.
3. Create Secrets as documented below.
    * AZURE_CREDENTIALS
    * PREFIX
4. Clone the [ARD repo](https://github.com/msft-davidlee/azure-resource-discovery) locally.
5. Run the following command within the ARD repo root directory against your local manifest file. Be sure to change the REPO_PATH to the correct one. ``` .\Apply.ps1 -ManifestFilePath "C:\REPO_PATH\manifest.json" ```
6. If all goes well, you should see resource groups created in your Azure Subscription as specified in the manifest.json file with Azure Policies applied for resource tagging.
7. Run a script to assign the service principal you have created with Contributor access to all the resource groups. ``` .\AssignServicePrincipal.ps1 -SpDisplayName "REPLACE_WITH_SP_NAME" ```
8. Next, we need to create managed identity which can be used later in the other workloads. Run the following in the root directory ``` .\EnableSharedManagedIdentity.ps1 ```
9. This repo is already configured to execute a GitHub workflow to create shared resources as defined in the shared-services.bicep file. We can manually kick it off or make a small change it and commit so as to trigger a GitHub workflow.
10. When this is done, in the shared-services resource group, you should see shared resources such as Key Vault created.
11. You should also see a storage account created in personal resource group. This is your cloudshell specific storage account. Update the app.yaml under .github\workflows directory if you do not intend to use it so it will not be created. Follow this [step](https://learn.microsoft.com/en-us/azure/cloud-shell/persisting-shell-storage#use-existing-resources) to associate your cloudshell storage.

### AZURE_CREDENTIALS

In order to connect to your Azure Subscription to create the shared resources, we will need to create a service principal in Azure Active Directory. Create a Service Principal in AAD so we can assign this SP the role of Contributor in each of the Resource Group so it can create resources. You will use your Principal Id so we can assign you rights to shared resources such as Azure Key Vault. Note that you need to have rights for role assignments in your Subscription.

```json
{
    "clientId": "",
    "clientSecret": "",
    "subscriptionId": "",
    "tenantId": ""
}
```

### PREFIX

You will need to pass in a PREFIX secret for naming shared resources. The suggested Prefix convention is first name initial, last name initial, workload type like pla and a number begin with 01 So, John Doe would be jdpla01 and you would manually "increment" your last number. This is because services like Azure KeyVault which is soft-deleted cannot be easily recreated quickly and you need a different unique name. Notice that we have a max length of 7 for this prefix but we will also append either dev or prod to the name which makes it either 10 chars or 11 chars. Again, let's strive to keep it short.

## Have an issue?

You are welcome to create an issue if you need help but please note that there is no timeline to answer or resolve any issues you have with the contents of this repo. Use the contents of this repo at your own risk! If you are interested to maintain this, please feel free to reach out to be added as a contributor and send Pull Requests (PR).
