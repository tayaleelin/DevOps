using '../../../AzureResourceModules/modules/container-service/managed-clusters/main.bicep'

param name = readEnvironmentVariable('AKS_CLUSTER_NAME') ?? 'akscluster'
param primaryAgentPoolProfile = [
    {
        name: 'poolname'
        vmSize: 'Standard_DS3_v2'
        osDiskSizeGB: 128
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
    }
]
