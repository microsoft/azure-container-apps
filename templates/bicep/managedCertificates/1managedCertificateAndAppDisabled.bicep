param cappName string 
param location string = resourceGroup().location
param managedEnvironmentName string
param customDomainName string
param cappContainerImage string
param cappConsumptionCpu string
param cappConsumptionMemory string

resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: managedEnvironmentName
  location: location
  properties: {
    workloadProfiles: [
      {
          workloadProfileType: 'Consumption'
          name: 'Consumption'
      }
  ]
  }
}


resource appWithBindingDisabled 'Microsoft.App/containerApps@2023-05-01' = {
  name: cappName
  location: location
  properties: {
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        allowInsecure: false
        external: true
        targetPort: 80
        customDomains: [
          {
            name: customDomainName
            bindingType: 'Disabled'
          }
        ]
      }
    }
    environmentId: managedEnvironment.id
    template: {
      containers: [
        {
          image: cappContainerImage
          name: cappName
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
  }
}

resource managedEnvironmentManagedCertificate 'Microsoft.App/managedEnvironments/managedCertificates@2023-05-01' = {
  parent:managedEnvironment
  dependsOn: [
    appWithBindingDisabled
  ]
  name: '${cappName}-certificate'
  location: location
  properties: {
    subjectName: customDomainName
    domainControlValidation: 'CNAME'
  }
}

