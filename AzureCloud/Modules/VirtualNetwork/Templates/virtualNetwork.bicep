param location string = resourceGroup().location
param vnetName string
param vnetAddressPrefix string = '10.0.0.0/16'

resource vnetSubnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}
