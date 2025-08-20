param name string
param location string = resourceGroup().location
param tags object = {}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' = { // @2022-10-01
  name: name
  location: location
  tags: tags
  properties: {
  }
}

output name string = containerAppsEnvironment.name
output domain string = containerAppsEnvironment.properties.defaultDomain
