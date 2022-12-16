param keyVaultName string
param location string = resourceGroup().location

param certificatePermissions array = [
  'all'
]
param keyPermissions array = [
  'all'
]
param secretPermissions array = [
  'all'
]
param storagePermissions array = [
  'all'
]

param allowAzureServices bool = false
param allowedApplicationId string
param allowedApplicationObjectId string
param allowedApplicationTenantId string
param ipAddressRules array

@allowed([
  'standard'
  'premium'
])
param keyVaultSku string = 'standard'
param vnetName string

var bypassType = allowAzureServices ? 'AzureServices' : 'None'

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vnetName
}

resource keyVaultResource 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: [
      {
        applicationId: allowedApplicationId
        objectId: allowedApplicationObjectId
        permissions: {
          certificates: certificatePermissions
          keys: keyPermissions
          secrets: secretPermissions
          storage: storagePermissions
        }
        tenantId: allowedApplicationTenantId
      }
    ]
    tenantId: subscription().tenantId
    networkAcls: {
      bypass: bypassType
      defaultAction: 'Allow'
      ipRules: ipAddressRules
      virtualNetworkRules: [
        {
          id: vnet.id
        }
      ]
    }
    sku: {
      name: keyVaultSku
      family: 'A'
    }
  }
}
