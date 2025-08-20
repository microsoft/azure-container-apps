@description('Name of the Azure Container Apps environment')
param environmentName string = 'mycontainerappenv'

@description('Name of the virtual network')
param vnetName string = 'myVNet'

@description('Name of the subnet for the container app')
param subnetName string = 'mySubnet'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the container app')
param containerAppName string = 'mycontainerapp'

@description('Docker image to deploy')
param image string = 'mcr.microsoft.com/k8se/quickstart:latest'

@description('Name of the private endpoint')
param privateEndpointName string = 'myPrivateEndpoint'

@description('The name of the Front Door endpoint to create. This must be globally unique.')
param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'

var frontDoorProfileName = 'MyFrontDoor'
var frontDoorOriginGroupName = 'MyOriginGroup'
var frontDoorOriginName = 'MyACAAppOrigin'
var frontDoorRouteName = 'MyRoute'

/*
The following resources are created in this Bicep file:

Virtual Network (VNet)
Resource Type: Microsoft.Network/virtualNetworks
Purpose: Creates a virtual network to host subnets for various components, including private endpoints.

Subnet for Private Endpoint
Resource Type: Microsoft.Network/virtualNetworks/subnets
Purpose: Creates a subnet within the virtual network specifically for hosting private endpoints.

Private Endpoint
Resource Type: Microsoft.Network/privateEndpoints
Purpose: Creates a private endpoint to securely connect to the container app or other Azure services.

Azure Container Apps Environment
Resource Type: Microsoft.App/managedEnvironments
Purpose: Creates an environment for hosting Azure Container Apps.

Container App
Resource Type: Microsoft.App/containerApps
Purpose: Deploys a containerized application within the Azure Container Apps environment.

Private DNS Zone
Resource Type: Microsoft.Network/privateDnsZones
Purpose: Creates a private DNS zone for resolving private endpoint DNS names.

Private DNS Zone Group
Resource Type: Microsoft.Network/privateEndpoints/privateDnsZoneGroups
Purpose: Associates the private DNS zone with the private endpoint.

Azure Front Door Profile
Resource Type: Microsoft.Cdn/profiles
Purpose: Creates an Azure Front Door profile for global load balancing and high availability.

Azure Front Door Endpoint
Resource Type: Microsoft.Cdn/profiles/endpoints
Purpose: Creates an endpoint for the Azure Front Door profile.

Azure Front Door Backend Pool
Resource Type: Microsoft.Cdn/profiles/backendPools
Purpose: Configures a backend pool for the Azure Front Door to route traffic to the container app.
*/

// create a vnet and suvbnet for pe termination only for ACA we use a managed network
// CLI Details can be found here:
// https://learn.microsoft.com/en-us/azure/container-apps/how-to-use-private-endpoint?pivots=azure-cli

resource vnet 'Microsoft.Network/virtualNetworks@2024-03-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${subnetName}-pe'
        properties: {
          addressPrefixes: ['10.0.1.0/24']
          delegations: []
        }
      }
    ]
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: '${containerAppName}-connection'
        properties: {
          privateLinkServiceId: containerAppEnv.id
          groupIds: [
            'managedEnvironments'
          ]
          privateLinkServiceConnectionState: {
            actionsRequired: 'None'
            status: 'Approved'
          }
        }
      }
    ]
  }
}

// ACA Environment and application with public access disabled
resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-02-02-preview' = {
  name: environmentName
  location: location
  properties: {
    publicNetworkAccess: 'Disabled'

    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
      }
    ]
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-02-02-preview' = {
  name: containerAppName
  location: location
  properties: {
    environmentId: containerAppEnv.id
    workloadProfileName: 'Consumption'
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'Auto'
      }
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: image
          resources: {
            #disable-next-line BCP036
            cpu: '0.5'
            memory: '1Gi'
          }
        }
      ]
    }
  }
}

// Private DNS resources
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.${location}.azurecontainerapps.io'
  location: 'global'
  properties: {}
  dependsOn: [
    vnet
  ]
}

resource acaPrivateDnsZoneVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: 'dnszone-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Front Door Resources
// CLI Details can be found here:
// https://learn.microsoft.com/en-us/azure/container-apps/how-to-integrate-with-azure-front-door

resource frontDoorProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: frontDoorEndpointName
  parent: frontDoorProfile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: frontDoorOriginGroupName
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: null
  }
}

resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2024-09-01' = {
  name: frontDoorOriginName
  parent: frontDoorOriginGroup
  properties: {
    hostName: containerApp.properties.configuration.ingress.fqdn
    originHostHeader: containerApp.properties.configuration.ingress.fqdn
    priority: 1
    weight: 500
    sharedPrivateLinkResource: {
      groupId: 'managedEnvironments'
      privateLink: {
        id: containerAppEnv.id
      }
      privateLinkLocation: location
      requestMessage: 'AFD Private Link Request'
      status: 'Approved'
    }
  }
}

resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: frontDoorRouteName
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigin
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'MatchRequest'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}

module dnsARecord 'dns-a-record.bicep' = {
  name: 'dnsARecordModule'
  params: {
    privateDnsZoneName: privateDnsZone.name
    privateEndpointName: privateEndpoint.name
    containerAppEnv: containerAppEnv
  }
}

module containerAppEnvPrivateEndpoints 'containerappenv-pe.bicep' = {
  name: 'containerAppEnvPrivateEndpointsModule'
  params: {
    environmentName: containerAppEnv.name
  }
  dependsOn: [
    frontDoorOrigin
    privateEndpoint
  ]
}
