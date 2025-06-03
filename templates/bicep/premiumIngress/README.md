# Premium Ingress with Azure Container Apps

This Bicep template demonstrates how to deploy an Azure Container Apps environment with **Premium Ingress** enabled. The deployment is bare-bones without any extras such as a Container Registry or KeyVauly. It just includes a managed environment and an NGINX container app.



## Overview

Premium Ingress provides advanced networking capabilities for Azure Container Apps, including:
- Enhanced scalability and performance for proxy instances supporting the environment ingress.
- Longer connection timeouts.

For more details, refer to the official documentation: [Premium Ingress Mode](https://learn.microsoft.com/en-us/azure/container-apps/ingress-environment-configuration#premium-ingress-mode).



## Key Features of the Deployment

- **Premium Ingress Mode**: Configured with advanced ingress settings.
- **Workload Profiles**: Includes a workload profile (`ingresswp`) with a scalable configuration:
  - Minimum replicas: 2
  - Maximum replicas: 8
- **Ingress Configuration**:
  - Graceful termination period: 600 seconds.
  - Header count limit: 101.
  - Request idle timeout: 5 minutes.



## Deployment Steps

### 1. Define Variables
Set the resource group and location for the deployment:

```bash
export RESOURCE_GROUP="my-resource-group"
export LOCATION="eastus"
```

### 2. Create a Resource Group
Create the resource group where the resources will be deployed:

```bash
az group create --location $LOCATION --name $RESOURCE_GROUP
```

### 3. Deploy the Bicep Template
Deploy the `main.bicep` file to create the container apps environment and the NGINX container app:

```bash
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep
```

### 5. Verify the Deployment
After the deployment completes:
- Navigate to the Azure Portal.
- Locate the deployed **Container Apps Environment** (`premium-ingress-env-$SUFFIX`) and **NGINX Container App** (`nginx-app-$SUFFIX`) in the specified resource group.
- Verify that the premium ingress configuration is applied.



## Cleanup
To delete the resources created by this deployment, run:

```bash
az group delete --name $RESOURCE_GROUP --yes --no
```