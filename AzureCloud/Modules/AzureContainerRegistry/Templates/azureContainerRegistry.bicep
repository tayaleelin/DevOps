@minLength(5)
@maxLength(10)
@description('Provide a globally unique name of your Azure Container Registry')
param namePrefix string

@description('Provide a location for the registry.')
param location string = resourceGroup().location

@description('Provide a tier of your Azure Container Registry.')
param acrSku string = 'Basic'

param adminUserEnabled bool

param anonymousPullEnabled bool

var acrName = 'acr${namePrefix}${substring(uniqueString(resourceGroup().id), 0, 6)}'

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    anonymousPullEnabled: (acrSku != 'basic' && anonymousPullEnabled ? anonymousPullEnabled : false)
  }
}

@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer
