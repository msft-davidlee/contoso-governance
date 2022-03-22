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

// Configure Azure Blueprint Bicep on the Subscription level.
targetScope = 'subscription'

// All resources created by the blueprint should use this tag.
var rgs = [
  {
    name: 'shared-services'
    tags: {
      'stack-name': 'platform'
      'stack-environment': stackEnvironment
      'stack-sub-name': 'shared-services'
    }
    createManagedIdentity: false
  }
  {
    name: 'networking'
    tags: {
      'stack-name': 'platform'
      'stack-environment': stackEnvironment
      'stack-sub-name': 'networking'
    }
    createManagedIdentity: false
  }
  {
    name: 'ais'
    tags: {
      'stack-name': 'ais'
      'stack-environment': stackEnvironment
      'stack-sub-name': 'demo'
    }
    createManagedIdentity: true
  }
  {
    name: 'aks'
    tags: {
      'stack-name': 'ais'
      'stack-environment': stackEnvironment
      'stack-sub-name': 'demo'
    }
    createManagedIdentity: true
  }
  {
    name: 'apim'
    tags: {
      'stack-name': 'apim'
      'stack-environment': stackEnvironment
      'stack-sub-name': 'demo'
    }
    createManagedIdentity: true
  }
  {
    name: 'appservice'
    tags: {
      'stack-name': 'appservice'
      'stack-environment': stackEnvironment
      'stack-sub-name': 'demo'
    }
    createManagedIdentity: true
  }
  {
    name: 'asev3'
    tags: {
      'stack-name': 'asev3'
      'stack-environment': stackEnvironment
      'stack-sub-name': 'demo'
    }
    createManagedIdentity: true
  }
  {
    name: 'staticweb'
    tags: {
      'stack-name': 'staticweb'
      'stack-environment': stackEnvironment
      'stack-sub-name': 'demo'
    }
    createManagedIdentity: true
  }
]

// It would be great to use the same blueprint and we should, but it doesn't seem that we can create a loop
resource blueprints 'Microsoft.Blueprint/blueprints@2018-11-01-preview' = [for (rg, i) in rgs: {
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
resource spResourceGroupContributorRoleAssignment 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = [for (rg, i) in rgs: {
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
resource myResourceGroupRoleKeyVaultSecretsOfficerRoleAssignment 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = {
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

// Well-know policy defination: e56962a6-4747-49cd-b67b-bf8b01975c4c - Allowed locations
resource allowedLocations 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = {
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
// Configure Shared Azure Key Vault resource
resource sharedKeyVault 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = {
  name: 'shared-key-vault'
  kind: 'template'
  parent: blueprints[0]
  properties: {
    description: 'Shared keyvault resource used to store any application specific secrets used in configurations'
    displayName: 'Shared keyvault'
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
            'stack-name': 'shared-key-vault'
            'stack-environment': stackEnvironment
            'stack-sub-name': 'shared-services'
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
            'stack-name': 'shared-storage'
            'stack-environment': stackEnvironment
            'stack-sub-name': 'shared-services'
          }
          sku: {
            name: 'Standard_LRS'
          }
          kind: 'StorageV2'
          properties: {
            supportsHttpsTrafficOnly: true
            allowBlobPublicAccess: false
          }
        }
        {
          name: '${stackName}/default'
          type: 'Microsoft.Storage/storageAccounts/blobServices'
          apiVersion: '2021-08-01'
        }
        {
          name: '${stackName}/default/apps'
          type: 'Microsoft.Storage/storageAccounts/blobServices/containers'
          apiVersion: '2021-08-01'
        }
        {
          name: '${stackName}/default/certs'
          type: 'Microsoft.Storage/storageAccounts/blobServices/containers'
          apiVersion: '2021-08-01'
        }
      ]
    }
  }
}

// Configure user identities to represents apps hosted in each of the resource group that
// can be used to access Shared resources like Key Vault.
resource usersDefs 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = [for (rg, i) in rgs: if (rg.createManagedIdentity) {
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
            'stack-name': 'platform'
            'stack-environment': stackEnvironment
            'stack-sub-name': 'identity'
          }
        }
      ]
    }
  }
}]

output blueprints array = [for i in range(0, length(rgs)): {
  name: blueprints[i].name
}]
