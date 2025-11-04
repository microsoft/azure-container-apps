param containerAppsEnvironmentName string
param app1Name string
param app2Name string
param app3Name string
param app4Name string
param app5Name string

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
resource app4 'Microsoft.App/containerApps@2023-11-02-preview' existing = {
  name: app4Name
}
resource app5 'Microsoft.App/containerApps@2023-11-02-preview' existing = {
  name: app5Name
}

resource httpRouteConfig 'Microsoft.App/managedEnvironments/httpRouteConfigs@2024-10-02-preview' = {
  name: 'routeconfig1'
  parent: containerEnv
  properties: {
    rules: [
      // rules should be configured from specific to broad (similar to fw rules)
      {
        description: 'API Gateway Pattern'
        routes: [
          {
            match: {
              pathSeparatedPrefix: '/search'
              caseSensitive: false
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
        description: 'Pass-through'
        routes: [
          {
            match: {
              prefix: '/home'
            }
            action: {
              prefixRewrite: '/home'
            }
          }
        ]
        targets: [
          {
            containerApp: app3.name
          }
        ]
      }
      {
        description: 'Very Specific Remap'
        routes: [
          {
            match: {
              path: '/health'
            }
            action: {
              prefixRewrite: '/status'
            }
          }
        ]
        targets: [
          {
            containerApp: app4.name
          }
        ]
      }
      {
        description: 'App 5 Remap'
        routes: [
          {
            match: {
              prefix: '/app5'
            }
            action: {
              prefixRewrite: '/'
            }
          }
        ]
        targets: [
          {
            containerApp: app5.name
          }
        ]
      }
      {
        // this should be last since otherwise it will capture other paths/prefixes
        description: 'Root Path Mapping (default)'
        routes: [
          {
            match: {
              prefix: '/'
            }
            action: {
              prefixRewrite: '/api/v1/'
            }
          }
        ]
        targets: [
          {
            containerApp: app2.name
            // optional add revision
            // revision: app2--azd-1755189182
          }
        ]
      }
    ]
  }
  dependsOn: [
    app1
    app2
    app3
    app4
    app5
  ]
}


output routeconfigurl string = 'https://${httpRouteConfig.properties.fqdn}'