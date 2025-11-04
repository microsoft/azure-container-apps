# Rule-based routing in Azure Container Apps

This repo demonstrates how to use the rule-based routing feature in Azure Container Apps. It consists of the same [Python based application](./allapp/) deployed five times and the bicep files to deploy them.

## Quickstart

### Prerequisites

- [Azure Developer CLI (azd)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd?tabs=winget-windows%2Cbrew-mac%2Cscript-linux&pivots=os-windows)

### Deploy

1. Clone the repo
1. Run `azd up` to get started and follow the prompts to deploy the repo.

### Configure rule-based routing

The rule-based routing feature introduces the [httpRoutingConfig](https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2025-02-02-preview/managedenvironments/httprouteconfigs?pivots=deployment-language-bicep) which informs how traffic is routed to the application(s). For an example of the httpRoutingConfig, visit [infra/shared/http-routes.bicep](infra/shared/http-routes.bicep) in this repo.

To use rule-based routing, you will need to be on at least the 2024-10-02-preview version of the [Azure Container Apps API](https://learn.microsoft.com/rest/api/resource-manager/containerapps/http-route-config?view=rest-resource-manager-containerapps-2024-10-02-preview).

## How Routing Rules Work

Each routing rule receives a subdomain equal the name of the routing rule. The subdomain/URL for this example will be `http://routeConfig1...containerapps.io/`. Routing rules are evaluated in the order they are listed. Ideally they should be listed from **most specific to least specific** in order to execute the full evaluation chain (similar to firewall rules). When a request comes in, the first matching rule determines which app receives the request and how the path is transformed.

### Path Routing Examples

The following examples show how different request paths are routed to apps. Rules are ordered by specificity:

#### 1. Exact Path Match (Most Specific)
- **Pattern**: `/health` (exact match)
- **Target**: app4 with path rewrite to `/status`
- **Examples**:
  - `GET /health` → `$APP4/status`
  - `GET /health/ok` → Does NOT match (falls through to catch-all)

#### 2. Case-Sensitive Prefix Matching  
- **Pattern**: `/search` (case-insensitive match)
- **Target**: app1 with path stripping
- **Examples**:
  - `GET /search/boom` → `$APP1/boom`
  - `GET /SEARCH/boom` → `$APP1/boom` (if case-insensitive)

#### 3. Pass-through Prefix Matching
- **Pattern**: `/home` (prefix with pass-through)
- **Target**: app3 with path preservation
- **Examples**:
  - `GET /home` → `$APP3/home`
  - `GET /home/dashboard` → `$APP3/home/dashboard`
  - `GET /homeis127001` → `$APP3/homeis127001`
  - `GET /HOME` → Does NOT match (case-sensitive, falls through to catch-all)

#### 4. Service Prefix Matching
- **Pattern**: `/app5` (prefix with path stripping)
- **Target**: app5 with path stripping
- **Examples**:
  - `GET /app5` → `$APP5/`
  - `GET /app5/feature` → `$APP5/feature`
  - `GET /app5plusmore` → `$APP5/plusmore`

#### 5. Catch-All Default (Least Specific)
- **Pattern**: `/` (root prefix - matches everything)
- **Target**: app2 with path transformation
- **Examples**:
  - `GET /` → `$APP2/api/v1/`
  - `GET /howdy` → `$APP2/api/v1/howdy`
  - `GET /HOME` → `$APP2/api/v1/HOME` (when no other rules match)
  - `GET /health/ok` → `$APP2/api/v1/health/ok` (when exact `/health` doesn't match)

### Key Routing Concepts

- **Rule Order Matters**: More specific rules must come before general ones
- **First Match Wins**: Once a rule matches, evaluation stops
- **Path Transformations**: Each rule can rewrite the path before forwarding to the target app
- **Case Sensitivity**: Rules are case-sensitive by default


**The following properties are currently supported:**
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
You can add this in the main.bicep file after the httprouteconfig and apps resources have been provisioned. As a extra check you can add a `dependsOn:[app1,app2,app3,app4,app5,httprouteconfig]` check as well.


### Feedback

For general feedback and questions please use [Roadmap: URL Based Routing](https://github.com/microsoft/azure-container-apps/issues/591#issuecomment-2523412443). To report bugs please use [Container Apps Issues](https://github.com/microsoft/azure-container-apps/issues).
