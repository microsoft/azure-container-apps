targetScope = 'resourceGroup'


// Generate a random alphanumeric sequence based on subscription ID, resource group name, and location
var randomSuffix = substring(toLower(uniqueString(subscription().id, resourceGroup().name, resourceGroup().location)), 0, 5)

// Define the container apps environment
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2025-02-02-preview' = {
  name: 'premium-ingress-env-${randomSuffix}'
  location: resourceGroup().location
  properties: {
    workloadProfiles: [
      {
        name: 'ingresswp'
        workloadProfileType: 'D4'
        minimumCount: 2
        maximumCount: 5
      }
    ]
    // Full docs here:
    // https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2025-02-02-preview/managedenvironments?pivots=deployment-language-arm-template#ingressconfiguration-1
    ingressConfiguration: {
      workloadProfileName: 'ingresswp'
      // NOTE: These are still required by the API but will not be used by the control plane anymore
      // minimumCount and maximumCount of the workloadProfile will become node scale.
      scale: {
        minReplicas: 2
        maxReplicas: 8
      }
      // Give 600 seconds for clients to gracefully disconnect.
      terminationGracePeriodSeconds: 600
      headerCountLimit: 101
      // Maximum length requests can last in minutes
      requestIdleTimeout: 5
    }
  }
}


// Define the NGINX container app
resource nginxContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'nginx-app-${randomSuffix}'
  location: resourceGroup().location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: [
        {
          name: 'nginx'
          image: 'nginx:latest'
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
    }
  }
}