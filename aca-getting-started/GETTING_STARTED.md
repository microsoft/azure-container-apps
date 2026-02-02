# Getting Started with Azure Container Apps

Welcome to Azure Container Apps! This guide will help you get started quickly.

## What is Azure Container Apps?

Azure Container Apps is a fully managed serverless container service that enables you to build and deploy modern apps and microservices using serverless containers. It's built on Kubernetes but abstracts away the complexity of managing infrastructure.

### Key Benefits

- **Serverless**: No infrastructure management required
- **Fully Managed**: Automatic scaling, patching, and updates
- **Microservices Ready**: Built-in support for Dapr
- **Event-Driven**: KEDA-based autoscaling
- **Cost-Effective**: Pay only for what you use
- **Developer-Friendly**: Simple deployment from containers

## Prerequisites

Before you begin, ensure you have:

- An Azure subscription ([Create free account](https://azure.microsoft.com/free/))
- Azure CLI installed ([Installation guide](https://learn.microsoft.com/cli/azure/install-azure-cli))
- Docker installed (for building containers)
- A code editor (VS Code recommended)

## Quick Start: Deploy Your First App

### Option 1: Azure Portal (No Code)

1. **Sign in** to the [Azure Portal](https://portal.azure.com)
2. Click **Create a resource**
3. Search for **Container Apps**
4. Click **Create**
5. Fill in the basic details:
   - Subscription
   - Resource group
   - Container app name
   - Region
6. Choose a container image (use quickstart image or your own)
7. Click **Review + create**
8. Click **Create**

🎉 Your first container app is deployed!

### Option 2: Azure CLI (5 Minutes)

```bash
# 1. Install the Container Apps extension
az extension add --name containerapp --upgrade

# 2. Register required namespaces
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights

# 3. Set variables
RESOURCE_GROUP="my-container-apps"
LOCATION="eastus"
CONTAINERAPPS_ENVIRONMENT="my-environment"

# 4. Create a resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# 5. Create a Container Apps environment
az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# 6. Deploy your first container app
az containerapp create \
  --name my-first-app \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --target-port 80 \
  --ingress 'external' \
  --query properties.configuration.ingress.fqdn
```

### Option 3: VS Code Extension

1. Install the [Azure Container Apps extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurecontainerapps)
2. Open the Azure view in VS Code
3. Sign in to Azure
4. Right-click on your subscription
5. Select **Create Container App**
6. Follow the prompts

## Next Steps

### 1. Learn Core Concepts

- [Environments](https://learn.microsoft.com/azure/container-apps/environment) - Understand container app environments
- [Revisions](https://learn.microsoft.com/azure/container-apps/revisions) - Learn about app versioning
- [Scaling](https://learn.microsoft.com/azure/container-apps/scale-app) - Configure autoscaling

### 2. Deploy Your Own Application

```bash
# Build your container
docker build -t myapp:v1 .

# Tag for Azure Container Registry
docker tag myapp:v1 myregistry.azurecr.io/myapp:v1

# Push to registry
az acr login --name myregistry
docker push myregistry.azurecr.io/myapp:v1

# Deploy to Container Apps
az containerapp create \
  --name myapp \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image myregistry.azurecr.io/myapp:v1 \
  --target-port 8080 \
  --ingress external \
  --registry-server myregistry.azurecr.io
```

### 3. Explore Advanced Features

- **Microservices with Dapr**: [Tutorial](https://learn.microsoft.com/azure/container-apps/microservices-dapr)
- **Authentication**: [Setup guide](https://learn.microsoft.com/azure/container-apps/authentication)
- **Custom Domains**: [Configure SSL](https://learn.microsoft.com/azure/container-apps/custom-domains-certificates)
- **Observability**: [Logging and monitoring](https://learn.microsoft.com/azure/container-apps/observability)

## Common Scenarios

### Scenario 1: Deploy a Web API

```bash
az containerapp create \
  --name my-api \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image myregistry.azurecr.io/api:latest \
  --target-port 3000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 10
```

### Scenario 2: Deploy a Background Worker

```bash
az containerapp create \
  --name my-worker \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image myregistry.azurecr.io/worker:latest \
  --min-replicas 1 \
  --max-replicas 5
```

### Scenario 3: Deploy with Environment Variables

```bash
az containerapp create \
  --name my-app \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image myregistry.azurecr.io/app:latest \
  --env-vars \
    "API_URL=https://api.example.com" \
    "LOG_LEVEL=info"
```

### Scenario 4: Deploy with Secrets

```bash
# Create app with secret
az containerapp create \
  --name my-app \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image myregistry.azurecr.io/app:latest \
  --secrets "db-password=MySecretPassword123" \
  --env-vars "DB_PASSWORD=secretref:db-password"
```

## Best Practices

### 1. Use Container Registries
- Azure Container Registry for private images
- Enable admin user or use managed identities
- Implement image scanning and security

### 2. Configure Health Probes
```bash
az containerapp create \
  --name my-app \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image myapp:latest \
  --health-probe-type liveness \
  --health-probe-path /health \
  --health-probe-interval 30
```

### 3. Implement Proper Scaling
```bash
az containerapp create \
  --name my-app \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image myapp:latest \
  --min-replicas 2 \
  --max-replicas 10 \
  --scale-rule-name http-rule \
  --scale-rule-type http \
  --scale-rule-http-concurrency 50
```

### 4. Use Managed Identities
- Avoid storing credentials
- Use managed identities for Azure resource access
- Integrate with Azure Key Vault

### 5. Enable Logging and Monitoring
```bash
# View logs
az containerapp logs show \
  --name my-app \
  --resource-group $RESOURCE_GROUP \
  --follow

# View metrics
az monitor metrics list \
  --resource $RESOURCE_ID \
  --metric-names Requests
```

## Troubleshooting

### Issue: App not starting

```bash
# Check logs
az containerapp logs show \
  --name my-app \
  --resource-group $RESOURCE_GROUP \
  --tail 100

# Check revision status
az containerapp revision list \
  --name my-app \
  --resource-group $RESOURCE_GROUP
```

### Issue: Can't access the app

```bash
# Verify ingress settings
az containerapp show \
  --name my-app \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress
```

### Issue: App scaling issues

```bash
# Check scaling rules
az containerapp show \
  --name my-app \
  --resource-group $RESOURCE_GROUP \
  --query properties.template.scale
```

## Resources

- **Documentation**: [Official Docs](https://learn.microsoft.com/azure/container-apps/)
- **Samples**: [GitHub Samples](https://github.com/Azure-Samples?q=container-apps)
- **Community**: [GitHub Discussions](https://github.com/microsoft/azure-container-apps/discussions)
- **Support**: [Microsoft Q&A](https://learn.microsoft.com/answers/tags/495/azure-container-apps)

## Learning Path

1. ✅ Deploy your first container app
2. 📚 Understand environments and revisions
3. 🔧 Configure scaling and health probes
4. 🌐 Set up custom domains
5. 🔐 Implement authentication
6. 📊 Configure observability
7. 🚀 Deploy microservices with Dapr
8. 🔄 Set up CI/CD pipelines

## What's Next?

- [Tutorial: Communication between microservices](https://learn.microsoft.com/azure/container-apps/communicate-between-microservices)
- [Tutorial: Deploy a Dapr application](https://learn.microsoft.com/azure/container-apps/microservices-dapr)
- [Explore reference architectures](https://learn.microsoft.com/azure/architecture/browse/?products=azure-container-apps)

---

**Need Help?** Join the community on [GitHub Discussions](https://github.com/microsoft/azure-container-apps/discussions) or check out [Microsoft Q&A](https://learn.microsoft.com/answers/tags/495/azure-container-apps).
