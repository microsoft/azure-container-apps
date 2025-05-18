@description('Name of the Azure Container Apps environment')
param environmentName string

resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: environmentName
}

module containerAppsEnvironmentPrivateAccess 'containerappenv-pe-approve.bicep' = {
  name: 'ContainerAppsEnvironment-PrivateAccess'
  params: {
    environmentName: environmentName
    containerAppsEnvironmentSharedPrivateLinks: filter(containerAppEnv.properties.privateEndpointConnections, connection => connection.properties.privateLinkServiceConnectionState.status == 'Pending')
  }
}
