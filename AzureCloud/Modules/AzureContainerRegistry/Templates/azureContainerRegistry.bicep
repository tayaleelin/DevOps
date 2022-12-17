@minLength(5)
@maxLength(10)
@description('Provide a globally unique name of your Azure Container Registry')
param namePrefix string

@description('Provide a location for the registry.')
param location string = resourceGroup().location

@description('Provide a tier of your Azure Container Registry.')
param acrSku string = 'Basic'

param adminUserEnabled bool = false
param anonymousPullEnabled bool = false

var acrName = 'acr${namePrefix}${substring(uniqueString(resourceGroup().id), 0, 6)}'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'acr${namePrefix}-mi'
  location: location
}

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  identity: managedIdentity
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    anonymousPullEnabled: ((acrSku != 'basic' && anonymousPullEnabled) ? anonymousPullEnabled : false)
  }
}

@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer
output principalId object = {
  principalId: acrResource.identity.principalId
  clientId: acrResource.identity.tenantId
  type: acrResource.identity.type
}
