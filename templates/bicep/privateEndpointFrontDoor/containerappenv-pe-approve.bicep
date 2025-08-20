@description('Name of the Azure Container Apps environment')
param environmentName string

@sys.description('Private Link resources that will be connected to the Azure Container Apps environment.')
param containerAppsEnvironmentSharedPrivateLinks array

resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: environmentName
}

resource containerAppEnvPrivateEndpointAccept 'Microsoft.App/managedEnvironments/privateEndpointConnections@2024-10-02-preview' = [for privateLink in containerAppsEnvironmentSharedPrivateLinks: {
  name: privateLink.name
  parent: containerAppEnv
  properties: {
    privateLinkServiceConnectionState: {
      status: 'Approved'
    }
  }
}]
