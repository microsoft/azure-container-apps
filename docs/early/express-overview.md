# Azure Container Apps Express Overview [Private Preview]

Azure Container Apps express gives you the fastest way to deploy containerized web applications to Azure. With opinionated defaults and a minimal configuration surface, express is a developer-first and agent-first platform designed to get your web apps running in the cloud as fast as possible. Rapid provisioning and scale-from-zero make express an ideal host for AI-powered applications and agent backends.

## Prerequisites

- An Azure account with an active subscription.
  - If you don't have one, you [can create one for free](https://azure.microsoft.com/pricing/purchase-options/azure-account?cid=msft_learn).
- A **Microsoft Entra ID account**. Only Entra ID accounts can sign in to Express. Non-AAD accounts, such as personal Microsoft accounts, aren't supported.
- Install the [Azure CLI](/cli/azure/install-azure-cli).

## Quickstart: Deploy with the CLI

Get your first Express container app running with a few CLI commands.

### Update the Container Apps extension

Before you begin, upgrade the Azure Container Apps CLI extension to the required version.

```azurecli
az extension update --name containerapp
```

> [!NOTE]
> You need version **1.3.0b4** or later of the `containerapp` extension.

### Create an Express environment

Create a resource group and an Express environment. Replace `<ENVIRONMENT_NAME>` and `<RESOURCE_GROUP>` with your own values.

```azurecli
az containerapp env create \
  --environment-mode express \
  --name <ENVIRONMENT_NAME> \
  --resource-group <RESOURCE_GROUP> \
  --logs-destination none
```

### Deploy a container app

Deploy a container image to the Express environment.

```azurecli
az containerapp up \
  --image docker.io/nginx \
  --name <APP_NAME> \
  --resource-group <RESOURCE_GROUP>
```

## Region availability

During the private preview, Express is available only in the **West Central US** region. Support for more regions will be added in future releases.

## Supported features

Express launches with the following set of supported features. This list is updated weekly as new capabilities are enabled.

| Feature | Supported |
|---|---|
| Scale to zero | ✅ Yes |
| Image deployment (anonymous and token-based) | ✅ Yes |
| Multi replica | ✅ Yes |
| Environment variables | ✅ Yes |
| Enable ingress | ✅ Yes |
| New portal experience | ✅ Yes |
| Log streaming | ✅ Yes |
| Region restriction | ✅ Yes |
| Logs (Log Analytics) | ✅ Yes |
| Rolling updates | ⚠️ Partial |
| Secrets | ❌ No |
| Billing | ❌ No |
| Secrets from Key Vault | ❌ No |
| Autoscale (KEDA-based) | ❌ No |
| Managed identity (app runtime) | ❌ No |
| Managed identity (image pull) | ❌ No |
| VNet integration | ❌ No |
| Quota | ❌ No |
| Health probes | ❌ No |
| Exec access | ❌ No |
| Easy Auth | ❌ No |
| Metrics (Azure Monitor) | ❌ No |
| Custom domain (managed certificate) | ❌ No |
| IP restrictions | ❌ No |
| CORS | ❌ No |
| Logs (Azure Monitor) | ❌ No |
| Session affinity | ❌ No |
| Sidecar container | ❌ No |
| Init container | ❌ No |
| Volume mount | ❌ No |
| Ephemeral storage | ❌ No |
| GPU | ❌ No |
| Insecure HTTP ingress | ❌ No |
| Additional ports | ❌ No |
| App-to-app communication | ❌ No |
| Debug console | ❌ No |
| Deployment label | ❌ No |
| Language stack | ❌ No |
| Multi revision / traffic splitting | ❌ No |
| Resiliency | ❌ No |
| Source-to-cloud deployment | ❌ No |
| TCP protocol | ❌ No |
| Aspire | ❌ No |
| Maintenance window | ❌ No |
| OpenTelemetry | ❌ No |
| Premium ingress | ❌ No |
| Private endpoint | ❌ No |
| Workload profiles | ❌ No |
| Peer-to-peer encryption | ❌ No |
| Job | ❌ No |
| Single revision management | ❌ No |
| Custom domain (BYOC) | ❌ No |
| Environment custom domain suffix (BYOC) | ❌ No |
| Environment custom domain suffix (managed certificate) | ❌ No |
| Azure file storage | ❌ No |
| Zone redundancy | ❌ No |
| App-to-app (internal FQDN) | ❌ No |
| Internal vs. external apps | ❌ No |

## Filing issues

If you encounter issues or have feedback during the private preview, file an issue on the [Azure Container Apps GitHub repository](https://github.com/microsoft/azure-container-apps/). Start the issue title with **[EPP]** to identify it as an Express Private Preview issue.

For example: `[EPP] Deployment fails when using custom environment variables`

## Key benefits

Express removes infrastructure decisions so you can go from code to production quickly.

- **High-speed launch**: Deploy in minutes with no infrastructure tuning required. Scaling behavior is built in from the start.

- **Simple, powerful apps**: Run HTTP-first workloads including APIs, SaaS frontends, AI gateways, and event-driven web backends.

- **Automatic elasticity**: Scale from zero to hyperscale automatically. Express is designed for unpredictable traffic patterns, and scaling is handled for you.

Express also provides:

| Feature | Description |
|---|---|
| Scale from zero | Your app scales down to zero when idle and back up on demand, so you only pay for what you use. |
| High-speed startup | Optimized cold start ensures your app is ready to serve traffic quickly. |
| Opinionated defaults | Sensible defaults are applied automatically so you don't have to configure infrastructure settings. |
| Minimal configuration surface | Fewer decisions to make means faster time to production. |
| Developer velocity | Spend less time on infrastructure and more time writing code. |

## Common scenarios

Express is ideal for HTTP-based web workloads where speed of deployment and simplicity are priorities.

- **SaaS applications**: Launch SaaS products without worrying about scaling infrastructure.

- **AI app frontends**: Deploy AI-powered interfaces and gateways that scale with demand.

- **Developer tools**: Ship internal and external dev tools with zero-config deployment.

- **Web dashboards**: Build internal analytics, monitoring, and admin panels with instant availability.

- **Startups and new projects**: Go from idea to production in minutes. Prototype fast, and scale as you grow.

- **Rapid prototyping**: Build and validate ideas quickly, then keep running in production without replatforming.

## How express works

Express simplifies the deployment experience by removing the need to create and manage a Container Apps environment. You deploy your app directly, and the platform provisions the underlying resources for you.

- **No environment to manage**: Deploy your container app without creating or configuring an environment. Express handles infrastructure allocation automatically.

- **Consumption-based compute**: Express runs on consumption CPU with pay-as-you-go pricing. Your apps scale to zero when idle, so you only pay for the compute your app uses.

- **Opinionated defaults**: Configuration decisions like scaling rules, networking, and resource allocation are handled by the platform with production-ready defaults.

- **Request-driven duration**: Compute runs when your app receives requests and scales down when traffic stops.

- **Optimized cold start**: Express automatically optimizes cold-start behavior, so your app is ready to serve traffic quickly after scaling from zero.

## When to use express

Use the following table to determine if Express is the right fit for your workload.

| Scenario | Use express? | Alternative |
|---|---|---|
| Web apps and REST APIs | ✅ Yes | |
| SaaS frontends and AI gateways | ✅ Yes | |
| Rapid prototyping and startups | ✅ Yes | |
| Web dashboards and admin panels | ✅ Yes | |
| GPU workloads | ❌ No | Use [serverless GPUs](gpu-serverless-overview.md) with dedicated workload profiles |
| TCP-based services | ❌ No | Use standard [Container Apps environments](https://learn.microsoft.com/en-us/azure/container-apps/environment) |
| Jobs and batch processing | ❌ No | Use [Container Apps jobs](jobs.md) |
| Microservices with service discovery | ❌ No | Use standard [Container Apps environments](https://learn.microsoft.com/en-us/azure/container-apps/environment) |

## Considerations

Keep the following points in mind when using express:

- **HTTP workloads only**: Express supports web apps and APIs that communicate over HTTP. TCP-based workloads aren't supported.

- **Consumption CPU compute**: Express runs on consumption-based CPU compute. GPU workloads require standard Container Apps with [dedicated workload profiles](https://learn.microsoft.com/en-us/azure/container-apps/workload-profiles-overview).

- **Opinionated configuration**: Express uses opinionated defaults with a minimal configuration surface. If you need fine-grained control over compute, networking, or cold-start behavior, use standard Container Apps with a [workload profiles environment](https://learn.microsoft.com/en-us/azure/container-apps/environment).

- **Feature availability**: Express offers a focused set of features at launch. Some capabilities available in standard Container Apps environments, such as custom virtual networks, Dapr integration, and built-in service discovery, aren't available in Express.