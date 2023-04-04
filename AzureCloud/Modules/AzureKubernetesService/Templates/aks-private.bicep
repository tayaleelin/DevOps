@allowed([
  'Free'
  'Paid'
])
@description('Use Free or Paid for higher SLA')
param aksSkuTier string = 'Free'

param autoscaleProfile object = {
  'balance-similar-node-groups': 'true'
  'expander': 'random'
  'max-empty-bulk-delete': '10'
  'max-graceful-termination-sec': '600'
  'max-node-provision-time': '15m'
  'max-total-unready-percentage': '45'
  'new-pod-scale-up-delay': '0s'
  'ok-total-unready-count': '3'
  'scale-down-delay-after-add': '10m'
  'scale-down-delay-after-delete': '20s'
  'scale-down-delay-after-failure': '3m'
  'scale-down-unneeded-time': '10m'
  'scale-down-unready-time': '20m'
  'scale-down-utilization-threshold': '0.5'
  'scan-interval': '10s'
  'skip-nodes-with-local-storage': 'true'
  'skip-nodes-with-system-pods': 'true'
}

@allowed([
  ''
  'audit'
  'Audit'
  'deny'
  'Deny'
  'disabled'
  'Disabled'
])
@description('Enable the Azure Policy addon')
param azurePolicyEffect string = 'audit'

@allowed([
  'Baseline'
  'Restricted'
])
param azurePolicyInitiative string = 'Baseline'

@allowed([
  'mariner'
  'Ubuntu'
])
param clusterOsImage string = 'mariner'

@description('Cluster postfix')
param clusterPostfix string

param kubernetesVersion string = '1.26.0'

@description('Default location of the resource group')
param location string

param maxPodsCount int = 100
param minNodeCount int = 3
param maxNodeCount int = 6

@description('Disk size in GB. Note: Can not be larger than the maximum cache size')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 100

@allowed([
  'Ephemeral'
  'Managed'
])
@description('OS disk type for worker nodes')
param osDiskType string = 'Ephemeral'

@description('The resource Id of the user assigned identity of the cluster')
param uaiResourceIdAks string

@description('Channel for automatically upgrading Kubernetes clusters')
param autoUpgradeChannel string = 'stable'

@description('Enter an instance type for the system node pool')
param vmSizePlatform string = 'Standard_DS2_v2'
// ============================================================================
// Variables

// Addons for AKS
var aksAddons = {
  azurePolicy: {
    config: {
      version: 'v2'
    }
    enabled: true
  }
}

// Name of the AKS cluster
var clusterName = 'aks-${clusterPostfix}'

// Name of the Azure policy for AKS
var policyName = 'aks-${clusterPostfix}-policy'

// Name of the Vnet
var vnetName = 'vnet'

// Name of the subnet. Worker nodes of the cluster are places here
var subnetName = 'aks-${clusterPostfix}-sn'

// Policy baseline used for AKS
var policySetBaseline = '/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d'
var policySetRestrictive = '/providers/Microsoft.Authorization/policySetDefinitions/42b8ef37-b724-4e24-bbc8-7a7708edfe00'

// ============================================================================
// Resources

// Subnet used for worker nodes
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: '${vnetName}/${subnetName}'
}

// Azure policies for AKS
resource aks_policies 'Microsoft.Authorization/policyAssignments@2020-09-01' = if (!empty(azurePolicyEffect)) {
  name: '${policyName}-${azurePolicyInitiative}'
  location: location
  properties: {
    policyDefinitionId: azurePolicyInitiative == 'Baseline' ? policySetBaseline : policySetRestrictive
    parameters: {
      excludedNamespaces: {
        value: [
        ]
      }
      effect: {
        value: azurePolicyEffect
      }
    }
    displayName: 'Kubernetes pod security ${azurePolicyInitiative} standards for Linux-based workloads'
    description: 'As per: https://github.com/Azure/azure-policy/blob/master/built-in-policies/policySetDefinitions/Kubernetes/'
  }
}

// AKS controle plane and agent pool
resource aks 'Microsoft.ContainerService/managedClusters@2022-11-01' = {
  name: clusterName
  location: location
  sku: {
    name: 'Basic'
    tier: aksSkuTier
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uaiResourceIdAks}': {}
    }
  }
  tags: {
    resourceType: 'Microsoft.ContainerService/managedClusters'
    resourceDepartment: 'Azure Platform'
    apiVersion: '2023-01-01'
  }
  properties: {
    dnsPrefix: clusterName
    enableRBAC: true
    autoScalerProfile: autoscaleProfile
    addonProfiles: aksAddons
    kubernetesVersion: kubernetesVersion
    apiServerAccessProfile: {
      enablePrivateCluster: true
      enablePrivateClusterPublicFQDN: true
    }
    agentPoolProfiles: [
      {
        name: 'platform'
        count: 3
        vmSize: vmSizePlatform
        osDiskSizeGB: osDiskSizeGB
        osDiskType: osDiskType
        vnetSubnetID: subnet.id
        osType: 'Linux'
        osSKU: clusterOsImage
        maxCount: maxNodeCount
        minCount: minNodeCount
        maxPods: maxPodsCount
        enableAutoScaling: true
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
      }
    ]
    autoUpgradeProfile: {
      upgradeChannel: autoUpgradeChannel
    }
    nodeResourceGroup: '${substring(resourceGroup().name, 0, length(resourceGroup().name) - 3)}-noderesources-rg'
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      networkPolicy: 'calico'
      outboundType: 'loadBalancer'
      dockerBridgeCidr: '172.17.0.1/16'
      dnsServiceIP: '172.10.0.10'
      serviceCidr: '172.10.0.0/16'
    }
  }
}
