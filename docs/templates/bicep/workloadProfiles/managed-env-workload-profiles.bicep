

param logAnalyticsWorkspaceName string

param managedEnvironmentName string
param location string = resourceGroup().location

//az containerapp env workload-profile list-supported -l eastus
param workloadProfileType  string
param workloadProfileName string
param workloadProfileMinimumCount int
param workloadProfileMaximumCount int

//Container App in Dedicated Workload Profile
param cappDedicatedName string
param cappDedicatedContainerImage string
param cappDedicatedCpu string
param cappDedicatedMemory string

//Container App in Consumption Workload Profile
param cappConsumptionName string
param cappConsumptionContainerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
param cappConsumptionCpu string = '0.5'
param cappConsumptionMemory string = '1'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}


resource managedEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' = {
  name: managedEnvironmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        maximumCount: workloadProfileMaximumCount
        minimumCount: workloadProfileMinimumCount
        name: workloadProfileName
        workloadProfileType: workloadProfileType
      }
    ]
  }
}

resource containerAppInDedicatedWorkloadProfile 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: cappDedicatedName
  location: location
  properties: {
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        allowInsecure: false
        external: true
        targetPort: 80
      }
    }
    environmentId: managedEnvironment.id
    template: {
      containers: [
        {
          image: cappDedicatedContainerImage
          name: cappDedicatedName
          resources: {
            cpu: json('${cappDedicatedCpu}')
            memory: '${cappDedicatedMemory}Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
      }
    }
    workloadProfileName: workloadProfileName
  }
}

resource containerAppInConsumptionWorkloadProfile 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: cappConsumptionName
  location: location
  properties: {
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        allowInsecure: false
        external: true
        targetPort: 80
      }
    }
    environmentId: managedEnvironment.id
    template: {
      containers: [
        {
          image: cappConsumptionContainerImage
          name: cappConsumptionName
          resources: {
            cpu: json('${cappConsumptionCpu}')
            memory: '${cappConsumptionMemory}Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
      }
    }
    workloadProfileName: 'Consumption'
  }
}
