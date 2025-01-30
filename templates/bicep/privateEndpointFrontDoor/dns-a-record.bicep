param privateDnsZoneName string 
param privateEndpointName string
param containerAppEnv object


resource existingPrivateZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDnsZoneName
}

resource existingPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' existing = {
  name: privateEndpointName
}


// use privateEndpoint.customDnsConfigs[0].ipAddresses[0] to get the private IP address
// aca envs default domain containerAppEnv.properties.defaultDomain
resource dnsRecordSet 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  parent: existingPrivateZone
  name: containerAppEnv.properties.defaultDomain
  location: 'global'
  properties: {
    ttl: 3600
    aRecords: [
      {
        // we use the private endpoint IP from the subnet for our private DNS A record below
        ipv4Address: existingPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }

}

