@allowed([
  'dev'
  'prod'
])
param stackEnvironment string
param location string = 'centralus'
param svcPrincipalId string
param myPrincipalId string
param blueprintName string
param prefix string
param mgmtId string

// Configure Azure Blueprint Bicep on the Subscription level.
targetScope = 'subscription'

// All resources created by the blueprint should use this tag.
var rgs = [
  {
    // Shared services is not created in Dev. We intend for Dev apps to leverage Prod shared services
    name: 'shared-services'
    tags: {
      'mgmt-id': mgmtId
      'stack-name': 'shared-services'
      'stack-environment': stackEnvironment
    }
    createManagedIdentity: false
    allResourcesDoNotDeleteInDev: false
    skipInDev: true
  }
  {
    // Personal rg is created only in Prod and stores your personal storage account for Cloud Shell.
    name: 'personal'
    tags: {
      'mgmt-id': mgmtId
      'stack-name': 'personal'
      'stack-environment': stackEnvironment
    }
    createManagedIdentity: false
    allResourcesDoNotDeleteInDev: false
    skipInDev: true
  }
  {
    name: 'networking'
    tags: {
      'mgmt-id': mgmtId
      'stack-name': 'networking'
      'stack-environment': stackEnvironment
    }
    createManagedIdentity: false
    allResourcesDoNotDeleteInDev: true
    skipInDev: false
  }
  {
    name: 'ais'
    tags: {
      'mgmt-id': mgmtId
      'stack-name': 'ais'
      'stack-environment': stackEnvironment
    }
    createManagedIdentity: true
    allResourcesDoNotDeleteInDev: true
    skipInDev: false
  }
  {
    name: 'aks'
    tags: {
      'mgmt-id': mgmtId
      'stack-name': 'aks'
      'stack-environment': stackEnvironment
    }
    createManagedIdentity: true
    allResourcesDoNotDeleteInDev: true
    skipInDev: false
  }
  {
    name: 'apim'
    tags: {
      'mgmt-id': mgmtId
      'stack-name': 'apim'
      'stack-environment': stackEnvironment
    }
    createManagedIdentity: true
    allResourcesDoNotDeleteInDev: true
    skipInDev: false
  }
  {
    name: 'appservice'
    tags: {
      'mgmt-id': mgmtId
      'stack-name': 'appservice'
      'stack-environment': stackEnvironment
    }
    createManagedIdentity: true
    allResourcesDoNotDeleteInDev: true
    skipInDev: false
  }
  {
    name: 'asev3'
    tags: {
      'mgmt-id': mgmtId
      'stack-name': 'asev3'
      'stack-environment': stackEnvironment
    }
    createManagedIdentity: true
    allResourcesDoNotDeleteInDev: true
    skipInDev: false
  }
  {
    name: 'staticweb'
    tags: {
      'mgmt-id': mgmtId
      'stack-name': 'staticweb'
      'stack-environment': stackEnvironment
    }
    createManagedIdentity: true
    allResourcesDoNotDeleteInDev: true
    skipInDev: false
  }
]

// It would be great to use the same blueprint and we should, but it doesn't seem that we can create a loop
resource blueprints 'Microsoft.Blueprint/blueprints@2018-11-01-preview' = [for (rg, i) in rgs: if (stackEnvironment == 'prod' || (stackEnvironment == 'dev' && !rg.skipInDev)) {
  name: '${blueprintName}${rg.name}'
  properties: {
    description: '${blueprintName} ${rg.name} blueprint'
    displayName: blueprintName
    parameters: {}
    resourceGroups: {
      ResourceGroup1: {
        name: '${rg.name}-${stackEnvironment}'
        location: location
        tags: rg.tags
        metadata: {
          displayName: '${rg.name}-${stackEnvironment}'
        }
      }
    }
    targetScope: 'subscription'
  }
}]

var contributorRoleIdRes = '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
resource spResourceGroupContributorRoleAssignment 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = [for (rg, i) in rgs: if (stackEnvironment == 'prod' || (stackEnvironment == 'dev' && !rg.skipInDev)) {
  name: '${rg.name}-contribitor'
  kind: 'roleAssignment'
  parent: blueprints[i]
  properties: {
    displayName: 'Service Principal : Contributor'
    principalIds: [
      svcPrincipalId
    ]
    resourceGroup: 'ResourceGroup1'
    roleDefinitionId: contributorRoleIdRes
  }
}]

var keyVaultSecretsOfficer = '/providers/Microsoft.Authorization/roleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
resource myResourceGroupRoleKeyVaultSecretsOfficerRoleAssignment 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = if (stackEnvironment == 'prod') {
  name: 'shared-services-kv-secrets'
  kind: 'roleAssignment'
  parent: blueprints[0]
  properties: {
    displayName: 'My User : Contributor'
    principalIds: [
      myPrincipalId
    ]
    resourceGroup: 'ResourceGroup1'
    roleDefinitionId: keyVaultSecretsOfficer
  }
}

var keyVaultSecretsUser = '/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6'
resource spResourceGroupRoleKeyVaultSecretsUserRoleAssignment 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = if (stackEnvironment == 'prod') {
  name: 'shared-services-kv-secretsuser'
  kind: 'roleAssignment'
  parent: blueprints[0]
  properties: {
    displayName: 'Service Principal : Key Vault Secrets User'
    principalIds: [
      svcPrincipalId
    ]
    resourceGroup: 'ResourceGroup1'
    roleDefinitionId: keyVaultSecretsUser
  }
}

var appConfigDataReader = '/providers/Microsoft.Authorization/roleDefinitions/516239f1-63e1-4d78-a4de-a74fb236a071'
resource spAppConfigDataReaderRoleAssignment 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = if (stackEnvironment == 'prod') {
  name: 'shared-services-appconfigreader'
  kind: 'roleAssignment'
  parent: blueprints[0]
  properties: {
    displayName: 'Service Principal : App Configuration Data Reader'
    principalIds: [
      svcPrincipalId
    ]
    resourceGroup: 'ResourceGroup1'
    roleDefinitionId: appConfigDataReader
  }
}

// This is needed because there is a script to configure route table on application gateway subnet and it needs to read 
// the route table created in the aks node rg.
// Assignment is on Subscription level.
var networkContributor = '/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
resource spNetworkContributorRoleAssignment 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = if (stackEnvironment == 'prod') {
  name: 'subscription-network-contributor'
  parent: blueprints[0]
  kind: 'roleAssignment'
  properties: {
    principalIds: [
      svcPrincipalId
    ]
    roleDefinitionId: networkContributor
  }
}

// Well-know policy defination: e56962a6-4747-49cd-b67b-bf8b01975c4c - Allowed locations
resource allowedLocations 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = if (stackEnvironment == 'prod') {
  name: 'sub-not-allowed-location'
  kind: 'policyAssignment'
  parent: blueprints[0]
  properties: {
    displayName: 'Allowed locations'
    description: 'The list of locations that can be specified when deploying resources.'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')
    parameters: {
      listOfAllowedLocations: {
        value: [
          'centralus'
          'eastus2'
          'northcentralus'
          'southcentralus'
          'eastus'
          'westus'
        ]
      }
    }
  }
}

var stackName = '${prefix}${stackEnvironment}'
// Configure Shared resources such as Azure Key Vault resource - This will be created in production and the single instances will be shared in Dev and Prod.
// to save cost.
resource sharedServices 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = if (stackEnvironment == 'prod') {
  name: 'shared-resources'
  kind: 'template'
  parent: blueprints[0]
  properties: {
    description: 'Shared resources used to store any application specific secrets used in configurations'
    displayName: 'Shared resources'
    parameters: {}
    resourceGroup: 'ResourceGroup1'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      resources: [
        {
          name: stackName
          type: 'Microsoft.KeyVault/vaults'
          apiVersion: '2021-11-01-preview'
          location: location
          tags: {
            'mgmt-id': mgmtId
            'stack-name': 'shared-key-vault'
            'stack-environment': stackEnvironment
          }
          properties: {
            sku: {
              name: 'standard'
              family: 'A'
            }
            enableSoftDelete: false
            enableRbacAuthorization: true
            enabledForTemplateDeployment: true
            enablePurgeProtection: true
            tenantId: subscription().tenantId
          }
        }
        {
          name: stackName
          type: 'Microsoft.Storage/storageAccounts'
          apiVersion: '2021-02-01'
          location: location
          tags: {
            'mgmt-id': mgmtId
            'stack-name': 'shared-storage'
            'stack-environment': stackEnvironment
          }
          sku: {
            name: 'Standard_LRS'
          }
          kind: 'StorageV2'
          properties: {
            supportsHttpsTrafficOnly: true
            allowBlobPublicAccess: false
          }
          resources: [
            {
              name: 'default/apps'
              type: 'blobServices/containers'
              apiVersion: '2021-08-01'
              dependsOn: [
                stackName
              ]
              properties: {
                publicAccess: 'None'
              }
            }
            {
              name: 'default/certs'
              type: 'blobServices/containers'
              apiVersion: '2021-08-01'
              dependsOn: [
                stackName
              ]
              properties: {
                publicAccess: 'None'
              }
            }
          ]
        }
        {
          name: stackName
          type: 'Microsoft.ContainerRegistry/registries'
          apiVersion: '2021-06-01-preview'
          location: location
          tags: {
            'stack-name': 'shared-container-registry'
            'stack-environment': stackEnvironment
          }
          sku: {
            name: 'Basic'
          }
          properties: {
            publicNetworkAccess: 'Enabled'
            // Have to enable Admin user in order for Container Apps to access ACR.
            adminUserEnabled: true
            anonymousPullEnabled: false
            policies: {
              retentionPolicy: {
                days: 3
              }
            }
          }
        }
        {
          name: stackName
          type: 'Microsoft.AppConfiguration/configurationStores'
          apiVersion: '2021-10-01-preview'
          location: location
          tags: {
            'mgmt-id': mgmtId
            'stack-name': 'shared-configuration'
            'stack-environment': stackEnvironment
          }
          sku: {
            name: 'free'
          }
          properties: {
            disableLocalAuth: true
            enablePurgeProtection: false
            publicNetworkAccess: 'Enabled'
          }
        }
      ]
    }
  }
}

var personalStackName = '${stackName}cs'
resource personal 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = if (stackEnvironment == 'prod') {
  name: 'personal-resources'
  kind: 'template'
  parent: blueprints[1]
  properties: {
    description: 'Personal resources only for things like CloudShell'
    displayName: 'Personal resources'
    parameters: {}
    resourceGroup: 'ResourceGroup1'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      resources: [
        {
          name: personalStackName
          type: 'Microsoft.Storage/storageAccounts'
          apiVersion: '2021-02-01'
          location: location
          tags: {
            'mgmt-id': mgmtId
            'stack-name': 'personal-storage'
            'stack-environment': stackEnvironment
          }
          sku: {
            name: 'Standard_LRS'
          }
          kind: 'StorageV2'
          properties: {
            supportsHttpsTrafficOnly: true
            allowBlobPublicAccess: false
          }
          resources: [
            {
              name: 'default/cloudshell'
              type: 'fileServices/shares'
              apiVersion: '2021-09-01'
              dependsOn: [
                personalStackName
              ]
              properties: {
                accessTier: 'TransactionOptimized'
                shareQuota: 6
                enabledProtocols: 'SMB'
              }
            }
          ]
        }
      ]
    }
  }
}

// Configure user identities to represents apps hosted in each of the resource group that
// can be used to access Shared resources like Key Vault.
resource usersDefs 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = [for (rg, i) in rgs: if ((rg.createManagedIdentity && stackEnvironment == 'prod') || (rg.createManagedIdentity && stackEnvironment == 'dev' && !rg.skipInDev)) {
  kind: 'template'
  name: rg.name
  parent: blueprints[i]
  properties: {
    description: 'Managed user identity for apps hosted in ${rg.name}'
    displayName: 'User identity.'
    parameters: {}
    resourceGroup: 'ResourceGroup1'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      resources: [
        {
          name: rg.name
          type: 'Microsoft.ManagedIdentity/userAssignedIdentities'
          apiVersion: '2018-11-30'
          location: location
          tags: {
            'mgmt-id': mgmtId
            'stack-name': 'identity'
            'stack-environment': stackEnvironment
          }
        }
      ]
    }
  }
}]

output blueprints array = [for i in range(0, length(rgs)): {
  name: blueprints[i].name
  allResourcesDoNotDeleteInDev: rgs[i].allResourcesDoNotDeleteInDev
  skipInDev: rgs[i].skipInDev
}]
