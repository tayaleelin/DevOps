param namePrefix string
@secure()
param servicePrincipalClientId string
@secure()
param servicePrincipalClientSecret string

param clusterName string = '${namePrefix}-aks'
param location string = resourceGroup().location
param kubernetesVersion string = '1.25'
param vmSize string = 'Standard_DS3_v2'
param vnetAddressPrefix string = '10.0.0.0/8'
param subnetAddressPrefix string = '10.240.0.0/16'
param osDiskSizeGB int = 128

param now string = utcNow()

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
    name: '${namePrefix}-vnet'
    location: location
    properties: {
        addressSpace: {
            addressPrefixes: [
                vnetAddressPrefix
            ]
        }
        subnets: [
            {
                name: 'subnet-aks-${now}'
                properties: {
                    addressPrefix: subnetAddressPrefix
                }
            }
        ]
    }
}

module aks '../../../AzureResourceModules/modules/container-service/managed-clusters/main.bicep' = {
    name: clusterName
    params: {
        aksClusterKubernetesVersion: kubernetesVersion
        aksServicePrincipalProfile: {
            clientId: servicePrincipalClientId
            clientSecret: servicePrincipalClientSecret
        }
        name: clusterName
        location: location
        primaryAgentPoolProfile: [
            {
                name: 'default'
                vmSize: vmSize
                osDiskSizeGB: osDiskSizeGB
                count: 1
                osType: 'Linux'
                maxCount: 5
                minCount: 1
                enableAutoScaling: true
                scaleSetPriority: 'Regular'
                scaleSetEvictionPolicy: 'Delete'
                nodeLabels: {}
                nodeTaints: [
                    'CriticalAddonsOnly=true:NoSchedule'
                ]
                type: 'VirtualMachineScaleSets'
                availabilityZones: [
                    '1'
                    '2'
                    '3'
                ]
                maxPods: 30
                storageProfile: 'ManagedDisks'
                mode: 'System'
                tags: {}
                vnetSubnetID: vnet.properties.subnets[0].id
            }
        ]
    }
}
