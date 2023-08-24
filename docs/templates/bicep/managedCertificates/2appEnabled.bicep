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

resource managedEnvironmentManagedCertificate 'Microsoft.App/managedEnvironments/managedCertificates@2023-05-01' = {
  parent:managedEnvironment
  name: '${cappName}-certificate'
  location: location
  properties: {
    subjectName: customDomainName
    domainControlValidation: 'CNAME'
  }
}

resource appWithManagedCertificateUpdated 'Microsoft.App/containerApps@2023-05-01' = {
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
            bindingType: 'SniEnabled'
            certificateId: managedEnvironmentManagedCertificate.id
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
