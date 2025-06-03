param containerAppsEnvironmentName string
param location string
param tags object
param app1Name string
param app2Name string
param app3Name string

resource containerEnv 'Microsoft.App/managedEnvironments@2023-11-02-preview' existing = {
  name: containerAppsEnvironmentName
}

resource app1 'Microsoft.App/containerApps@2023-11-02-preview' existing = {
  name: app1Name
}

resource app2 'Microsoft.App/containerApps@2023-11-02-preview' existing = {
  name: app2Name
}

resource app3 'Microsoft.App/containerApps@2023-11-02-preview' existing = {
  name: app3Name
}

resource httpRouteConfig 'Microsoft.App/managedEnvironments/httpRouteConfigs@2024-10-02-preview' = {
  name: 'routeconfig1'
  parent: containerEnv
  location: location  
  properties: {
    rules: [
      {
        description: 'App 1 rule'
        routes: [
          {
            match: {
              prefix: '/app1'
            }
            action: {
              prefixRewrite: '/'
            }
          }
        ]
        targets: [
          {
            containerApp: app1.name
          }
        ]
      }
      {
        description: 'App 2 rule'
        routes: [
          {
            match: {
              prefix: '/app2'
            }
            action: {
              prefixRewrite: '/'
            }
          }
        ]
        targets: [
          {
            containerApp: app2.name
          }
        ]
      }
      {
        description: 'App 3 rule'
        routes: [
          {
            match: {
              prefix: '/'
            }
          }
        ]
        targets: [
          {
            containerApp: app3.name
          }
        ]
      }
    ]
  }
  dependsOn: [
    app1
    app2
    app3
  ]
}
