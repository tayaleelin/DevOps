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

@description('Default pull role guid for ACR permissions')
param acrRoleGuid string = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

var acrName = 'acr${namePrefix}${substring(uniqueString(resourceGroup().id), 0, 6)}'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'acr${namePrefix}-mi'
  location: location
}

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    anonymousPullEnabled: ((acrSku != 'basic' && anonymousPullEnabled) ? anonymousPullEnabled : false)
  }
}

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: acrRoleGuid
}

resource roleAssignmentContainerRegistry 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(managedIdentity.id, acrResource.id, roleDefinition.id)
  scope: acrResource
  properties: {
    principalId: managedIdentity.properties.principalId
    roleDefinitionId: roleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer
output acrName string = acrResource.name
