param prefix string
param location string = resourceGroup().location

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2022-05-01' = {
  location: location
  name: prefix
  properties: {
    disableLocalAuth: true
    enablePurgeProtection: false
    encryption: {
    }
    publicNetworkAccess: 'Enabled'
    softDeleteRetentionInDays: 0
  }
  sku: {
    name: 'free'
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  location: location
  name: prefix
  properties: {
    adminUserEnabled: true
    anonymousPullEnabled: false
    dataEndpointEnabled: false
    encryption: {
      status: 'disabled'
    }
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      azureADAuthenticationAsArmPolicy: {
        status: 'enabled'
      }
      exportPolicy: {
        status: 'enabled'
      }
      quarantinePolicy: {
        status: 'disabled'
      }
      retentionPolicy: {
        days: 3
        status: 'disabled'
      }
      softDeletePolicy: {
        retentionDays: 7
        status: 'disabled'
      }
      trustPolicy: {
        status: 'disabled'
        type: 'Notary'
      }
    }
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
  sku: {
    name: 'Basic'
  }
}

resource akv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  location: location
  name: prefix
  properties: {
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: false
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    publicNetworkAccess: 'Enabled'
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
  }
}

resource str 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  kind: 'StorageV2'
  location: location
  name: prefix
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
    minimumTlsVersion: 'TLS1_0'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    supportsHttpsTrafficOnly: true
  }
  sku: {
    name: 'Standard_LRS'
  }
}

resource str_default 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  parent: str
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource str_default_apps 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  parent: str_default
  name: 'apps'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    immutableStorageWithVersioning: {
      enabled: false
    }
    publicAccess: 'None'
  }
}

resource str_default_certs 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  parent: str_default
  name: 'certs'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    immutableStorageWithVersioning: {
      enabled: false
    }
    publicAccess: 'None'
  }
}

resource str_default_share 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  parent: str_default
  name: 'share'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    immutableStorageWithVersioning: {
      enabled: false
    }
    publicAccess: 'None'
  }
}
