targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param app1Exists bool
param app2Exists bool
param app3Exists bool
param app4Exists bool
param app5Exists bool
@secure()
param allappDefinition object

@description('Id of the user or app to assign application roles')
param principalId string

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module registry './shared/registry.bicep' = {
  name: 'registry'
  params: {
    location: location
    tags: tags
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
  }
  scope: rg
}

module keyVault './shared/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    tags: tags
    name: '${abbrs.keyVaultVaults}${resourceToken}'
    principalId: principalId
  }
  scope: rg
}

module appsEnv './shared/apps-env.bicep' = {
  name: 'apps-env'
  params: {
    name: '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    tags: tags
  }
  scope: rg
}

module app1 './app/app1.bicep' = {
  name: 'app1'
  params: {
    name: 'app1'
    location: location
    tags: union(tags, { 'azd-service-name': 'allapp' })
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}app1-${resourceToken}'
    containerAppsEnvironmentName: appsEnv.outputs.name
    containerRegistryName: registry.outputs.name
    exists: app1Exists
    appDefinition: allappDefinition
  }
  scope: rg
}

module app2 './app/app1.bicep' = {
  name: 'app2'
  params: {
    name: 'app2'
    location: location
    tags: tags
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}app2-${resourceToken}'
    containerAppsEnvironmentName: appsEnv.outputs.name
    containerRegistryName: registry.outputs.name
    exists: app2Exists
    appDefinition: allappDefinition
  }
  scope: rg
}

module app3 './app/app1.bicep' = {
  name: 'app3'
  params: {
    name: 'app3'
    location: location
    tags: tags
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}app3-${resourceToken}'
    containerAppsEnvironmentName: appsEnv.outputs.name
    containerRegistryName: registry.outputs.name
    exists: app3Exists
    appDefinition: allappDefinition
  }
  scope: rg
}

module app4 './app/app1.bicep' = {
  name: 'app4'
  params: {
    name: 'app4'
    location: location
    tags: tags
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}app4-${resourceToken}'
    containerAppsEnvironmentName: appsEnv.outputs.name
    containerRegistryName: registry.outputs.name
    exists: app4Exists
    appDefinition: allappDefinition
  }
  scope: rg
}

module app5 './app/app1.bicep' = {
  name: 'app5'
  params: {
    name: 'app5'
    location: location
    tags: tags
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}app5-${resourceToken}'
    containerAppsEnvironmentName: appsEnv.outputs.name
    containerRegistryName: registry.outputs.name
    exists: app5Exists
    appDefinition: allappDefinition
  }
  scope: rg
}

module httpRoutes './shared/http-routes.bicep' = {
  name: 'http-routes'
  params: {
    containerAppsEnvironmentName: appsEnv.outputs.name
    app1Name: app1.name
    app2Name: app2.name
    app3Name: app3.name
    app4Name: app4.name
    app5Name: app5.name
  }
  scope: rg
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.outputs.loginServer
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
