# Azure Container Apps - Frequently Asked Questions

## General Questions

### What is Azure Container Apps?

Azure Container Apps is a fully managed serverless container service that enables you to run microservices and containerized applications without managing complex infrastructure. It's built on Kubernetes but provides a simplified experience.

### How is Azure Container Apps different from Azure Kubernetes Service (AKS)?

| Feature | Azure Container Apps | Azure Kubernetes Service |
|---------|---------------------|-------------------------|
| **Management** | Fully managed, serverless | Managed control plane, you manage nodes |
| **Complexity** | Simplified, abstracted | Full Kubernetes API access |
| **Use Case** | Microservices, web apps, APIs, jobs | Complex K8s workloads, advanced scenarios |
| **Scaling** | Automatic, KEDA-based | Manual or custom autoscaling |
| **Pricing** | Pay-per-use (consumption) | Pay for nodes |
| **Best For** | Developers focused on apps | Teams needing full K8s control |

### When should I use Azure Container Apps?

Use Azure Container Apps when you:
- Want to focus on your application, not infrastructure
- Need automatic scaling based on HTTP traffic or events
- Are building microservices architectures
- Want built-in support for Dapr
- Need to run containerized jobs or background workers
- Prefer consumption-based pricing

### What container registries are supported?

Azure Container Apps supports:
- Azure Container Registry (ACR)
- Docker Hub
- GitHub Container Registry
- Any private registry that supports Docker Registry HTTP API V2

## Technical Questions

### What programming languages can I use?

Azure Container Apps is language-agnostic. Any language that can run in a container is supported:
- .NET (C#, F#)
- Java
- Node.js
- Python
- Go
- Rust
- PHP
- And more!

### What is the maximum size for a container app?

- **Memory**: Up to 4 GB per container
- **CPU**: Up to 2 vCPUs per container
- **Storage**: Ephemeral storage included; can mount Azure Files for persistent storage
- **Item Size**: 2 MB maximum per item (same as Cosmos DB, if using for state)

### How does scaling work?

Azure Container Apps supports multiple scaling modes:

1. **HTTP Scaling**: Based on concurrent requests
2. **Event-Driven**: KEDA scalers (Azure Queue, Service Bus, Kafka, etc.)
3. **CPU/Memory**: Based on resource utilization
4. **Custom Metrics**: Any metric from Azure Monitor
5. **Scale to Zero**: Automatically scale to zero when idle

Example:
```bash
az containerapp create \
  --name myapp \
  --min-replicas 0 \
  --max-replicas 10 \
  --scale-rule-name http-rule \
  --scale-rule-type http \
  --scale-rule-http-concurrency 50
```

### Can I use my own virtual network?

Yes! Azure Container Apps supports:
- VNET injection for private deployments
- Custom VNETs with user-defined routes
- Network Security Groups (NSGs)
- Private endpoints
- Integration with Azure Firewall

### How do I manage secrets?

Azure Container Apps provides multiple ways to manage secrets:

1. **Built-in Secrets**: Store secrets in Container Apps
```bash
az containerapp create \
  --secrets "api-key=MySecretValue"
```

2. **Azure Key Vault**: Reference secrets from Key Vault
```bash
az containerapp create \
  --secrets "api-key=keyvaultref:https://myvault.vault.azure.net/secrets/apikey,identityref:system"
```

3. **Managed Identities**: Use system or user-assigned managed identities

## Deployment Questions

### How do I deploy from GitHub?

Use GitHub Actions:

```yaml
name: Deploy to Azure Container Apps

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Log in to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Build and deploy
        uses: azure/container-apps-deploy-action@v1
        with:
          appName: my-app
          resourceGroup: my-rg
          imageToDeploy: myregistry.azurecr.io/myapp:${{ github.sha }}
```

### Can I use CI/CD pipelines?

Yes! Azure Container Apps works with:
- GitHub Actions
- Azure DevOps Pipelines
- GitLab CI/CD
- Jenkins
- Any CI/CD tool that can build containers

### How do I perform blue-green deployments?

Use revision management:

```bash
# Deploy new revision with 0% traffic
az containerapp update \
  --name myapp \
  --resource-group myrg \
  --image myapp:v2 \
  --revision-suffix v2

# Gradually shift traffic
az containerapp ingress traffic set \
  --name myapp \
  --resource-group myrg \
  --revision-weight latest=20 myapp--v1=80

# Full cutover
az containerapp ingress traffic set \
  --name myapp \
  --resource-group myrg \
  --revision-weight latest=100
```

## Pricing Questions

### How much does Azure Container Apps cost?

Azure Container Apps uses consumption-based pricing:

1. **Consumption Plan**:
   - Pay for vCPU and memory used
   - Scale to zero to avoid charges when idle
   - First 180,000 vCPU-seconds and 360,000 GiB-seconds free per month

2. **Dedicated Plan** (Workload Profiles):
   - Pay for dedicated hardware
   - Predictable costs
   - Better for consistently high workloads

[Pricing Calculator](https://azure.microsoft.com/pricing/calculator/?service=container-apps)

### Is there a free tier?

Yes! The consumption plan includes:
- 180,000 vCPU-seconds (50 hours at 1 vCPU)
- 360,000 GiB-seconds (100 hours at 1 GiB)
- Free per month, per subscription

Perfect for development and testing!

### How can I reduce costs?

1. **Scale to Zero**: Enable for apps with intermittent traffic
2. **Right-Size Resources**: Don't over-provision CPU/memory
3. **Use Spot Instances**: Available in workload profiles
4. **Optimize Container Images**: Smaller images = faster starts = lower costs
5. **Use Shared Environment**: Deploy multiple apps in one environment

## Dapr Questions

### What is Dapr?

Dapr (Distributed Application Runtime) is an open-source runtime that simplifies building microservices. Azure Container Apps has built-in Dapr support.

### How do I enable Dapr?

```bash
az containerapp create \
  --name myapp \
  --resource-group myrg \
  --environment myenv \
  --enable-dapr \
  --dapr-app-id myapp \
  --dapr-app-port 3000
```

### What Dapr components are supported?

All Dapr components are supported:
- State stores (Cosmos DB, Redis, etc.)
- Pub/sub (Service Bus, Event Hubs, etc.)
- Bindings (Storage, SQL, etc.)
- Secret stores (Key Vault, etc.)

## Monitoring & Observability

### How do I view logs?

```bash
# Console logs
az containerapp logs show \
  --name myapp \
  --resource-group myrg \
  --follow

# System logs
az monitor log-analytics query \
  --workspace myworkspace \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'myapp'"
```

### What monitoring tools are integrated?

- **Azure Monitor**: Metrics and logs
- **Application Insights**: APM and distributed tracing
- **Log Analytics**: Query and analyze logs
- **Azure Dashboards**: Custom visualizations
- **Alerts**: Automated notifications

### How do I enable Application Insights?

```bash
az containerapp create \
  --name myapp \
  --resource-group myrg \
  --environment myenv \
  --enable-dapr \
  --dapr-instrumentation-key $APP_INSIGHTS_KEY
```

Or use environment variables:
```bash
APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=..."
```

## Jobs Questions

### What are Container Apps Jobs?

Jobs are containerized tasks that run to completion:
- **Manual Jobs**: Triggered on-demand
- **Scheduled Jobs**: Run on a cron schedule
- **Event-Driven Jobs**: Triggered by events (queues, etc.)

### How do I create a scheduled job?

```bash
az containerapp job create \
  --name my-job \
  --resource-group myrg \
  --environment myenv \
  --trigger-type Schedule \
  --cron-expression "0 */6 * * *" \
  --image myregistry.azurecr.io/batch-job:latest
```

### Can jobs scale?

Yes! Event-driven jobs can scale based on:
- Queue length
- Topic messages
- Custom metrics

## Security Questions

### How is my app secured?

Azure Container Apps provides:
- **Network Isolation**: VNET integration
- **HTTPS**: Automatic TLS certificates
- **Authentication**: Built-in auth with Azure AD, GitHub, etc.
- **Managed Identities**: Secure access to Azure resources
- **Secrets Management**: Encrypted at rest
- **RBAC**: Role-based access control

### How do I enable authentication?

```bash
az containerapp auth update \
  --name myapp \
  --resource-group myrg \
  --enabled true \
  --redirect-provider microsoft \
  --client-id $CLIENT_ID \
  --client-secret $CLIENT_SECRET \
  --issuer https://login.microsoftonline.com/$TENANT_ID/v2.0
```

### Are containers isolated?

Yes! Each container app runs in its own:
- Network namespace
- Process namespace
- Container group

## Troubleshooting

### My app won't start. What should I check?

1. **Check logs**:
```bash
az containerapp logs show --name myapp --resource-group myrg
```

2. **Verify image**:
```bash
az containerapp show --name myapp --resource-group myrg --query "properties.template.containers[0].image"
```

3. **Check health probes**: Ensure your app responds to health checks

4. **Review resource limits**: Increase CPU/memory if needed

### How do I debug connection issues?

1. **Check ingress settings**: Verify external/internal configuration
2. **Test DNS**: Ensure FQDN resolves
3. **Review firewall rules**: Check NSGs and firewalls
4. **Examine VNET config**: Verify subnet and routing

### My app isn't scaling. Why?

Common issues:
- Scale rules not configured
- Min/max replicas set incorrectly
- Health probes failing
- Insufficient quotas

Check scaling configuration:
```bash
az containerapp show \
  --name myapp \
  --resource-group myrg \
  --query "properties.template.scale"
```

## Migration Questions

### Can I migrate from App Service?

Yes! Common migration path:
1. Containerize your application
2. Push to Azure Container Registry
3. Deploy to Container Apps
4. Configure custom domain and SSL
5. Update DNS

### Can I migrate from AKS?

Yes! Azure Container Apps supports most Kubernetes workloads. You may need to:
- Adapt Kubernetes manifests
- Replace custom CRDs with Container Apps features
- Simplify networking configuration

### Can I migrate from VMs?

Yes! Containerize your application:
1. Create a Dockerfile
2. Build and test locally
3. Push to a container registry
4. Deploy to Container Apps

## Getting Help

### Where can I get support?

- **Documentation**: [learn.microsoft.com/azure/container-apps](https://learn.microsoft.com/azure/container-apps/)
- **Microsoft Q&A**: [Q&A Forum](https://learn.microsoft.com/answers/tags/495/azure-container-apps)
- **GitHub**: [Discussions](https://github.com/microsoft/azure-container-apps/discussions)
- **Stack Overflow**: [azure-container-apps tag](https://stackoverflow.com/questions/tagged/azure-container-apps)
- **Azure Support**: [Create support ticket](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)

### How do I submit feature requests?

1. Check [existing issues](https://github.com/microsoft/azure-container-apps/issues)
2. Create a new issue with the "feature request" template
3. Engage with the community

### Where can I find code samples?

- [Azure Samples](https://github.com/Azure-Samples?q=container-apps)
- [Awesome Azure Container Apps](https://github.com/stuartleeks/awesome-azure-container-apps)
- [Official Documentation Samples](https://learn.microsoft.com/azure/container-apps/samples)

---

**Still have questions?** Ask on [Microsoft Q&A](https://learn.microsoft.com/answers/tags/495/azure-container-apps) or [GitHub Discussions](https://github.com/microsoft/azure-container-apps/discussions)!
