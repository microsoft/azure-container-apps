# Rule-based routing in Azure Container Apps

This repo demonstrates how to use the new rule-based routing feature in Azure Container Apps. It consists of three container apps and the bicep files to deploy them.

## Quickstart

### Prerequisites

- [AZD](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd?tabs=winget-windows%2Cbrew-mac%2Cscript-linux&pivots=os-windows)

### Deploy

1. Clone the repo
1. Run `azd up` to get started and follow the prompts to deploy the repo.

### Configure rule-based routing

The new rule-based routing feature introduces the httpRoutingConfig which informs how traffic is routed in the application. For an example of the httpRoutingConfig, visit [infra/shared/apps-env.bicep](infra/shared/apps-env.bicep) in this repo.

To use rule-based routing, you will need to be on the 2024-10-02-preview version of the [Azure Container Apps API](https://learn.microsoft.com/rest/api/resource-manager/containerapps/http-route-config?view=rest-resource-manager-containerapps-2024-10-02-preview).

The following is an example of how you can configure rule-based routing in your ARM/bicep templates.

### Example ARM/bicep

```armasm
resource httpRouteConfig 'Microsoft.App/managedEnvironments/httpRouteConfigs@2024-10-02-preview' = {
  parent: containerAppsEnvironment
  name: 'routeconfig1'
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
                    containerApp: 'app1'
                }
            ]
        }
        {
            description: 'App 2 rule'
            routes: [
                {
                    match: {
                        exact: '/app2'
                    }
                    action: {
                        prefixRewrite: '/'
                    }
                }
            ]
            targets: [
                {
                    containerApp: 'app2'
                }
            ]
        }
    ]
  }
}
```

Details:
The following properties are currently supported.
- `{name}` for an httpRouteComponent should be unique across containerAppNames + containerAppJobNames in the cluster.
- `rules` is an array of routing rules and their targets. They are evaluated in prority order based on the order they are defined.
- `routes` is an array of routes that will be matched against the incoming request. The first route that matches will be used.
- `matches` is an array of matching rules. These can have type `prefix`,`exact` or `pathseparatedprefix`. Any request that doesn't have a match will 404.
- `prefixRewrite` the URL path to modify the URL prefix path to
- `targets` takes one target application for which the routes in a rule will be forwaded to. These can only be container app names.

### Optional: Provisioning a Managed TLS/SSL Certificate for HTTPS

If you are using a **custom domain** in your `httpRouteConfig` and wish to access it over **HTTPS**, you need to provision a **managed TLS/SSL certificate** in Azure Container Apps. If you have bound your custom domain to the routing spec using `auto` bindingType then once the TLS certificate is provisioned successfully, it will automatically be added to the certificate id field in the spec and be bound to your routing config within the managed environment.
 
#### Steps:
 
1. **Ensure DNS is properly configured**  
   Your custom domain must have a valid DNS record pointing to your Azure Container App's ingress endpoint (typically a TXT record and a IP address of the Managed Environment). [Add a custom domain and certificate](https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-certificates?tabs=general&pivots=azure-cli#add-a-custom-domain-and-certificate)
 
2. **Add the `managedCertificate` resource to your Bicep template**  
   Here's an example:
 
   ```bicep
   resource managedCert 'Microsoft.App/managedEnvironments/managedCertificates@2024-10-02-preview' = {
     name: '${containerAppsEnvironment.name}/my-cert'
     location: location
     properties: {
       domainControlValidation: {
         type: 'HTTP'
       }
       subjectName: 'your.customdomain.com'
     }
   }
You can add this in the main.bicep file after the httprouteconfig and apps resources have been provisioned. As a extra check you can add a `dependsOn:[app1,app2,app3,httprouteconfig]` check as well

### What's next?
- Support for custom domains for the HTTProutingConfig
- Targeting of apps/revisions
- Header-based routing

### Feedback

For general feedback and questions please use [Roadmap: URL Based Routing](https://github.com/microsoft/azure-container-apps/issues/591#issuecomment-2523412443). To report bugs please use [Container Apps Issues](https://github.com/microsoft/azure-container-apps/issues).
