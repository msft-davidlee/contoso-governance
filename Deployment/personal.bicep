param prefix string
param location string = resourceGroup().location

resource str 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  kind: 'StorageV2'
  location: location
  name: '${prefix}cs'
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

resource str_default 'Microsoft.Storage/storageAccounts/fileServices@2022-05-01' = {
  parent: str
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    protocolSettings: {
      smb: {
      }
    }
    shareDeleteRetentionPolicy: {
      days: 7
      enabled: true
    }
  }
}

resource str_default_cloudshell 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-05-01' = {
  parent: str_default
  name: 'cloudshell'
  properties: {
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
    shareQuota: 6
  }
}
