# Bicep Deployment of ACA + Private Endpoint + Azure Front Door

These Bicep files automate the process outlined in these two articles:

* [Create a private link to an Azure Container App with Azure Front Door](https://learn.microsoft.com/en-us/azure/container-apps/how-to-integrate-with-azure-front-door)
* [Use a private endpoint with an Azure Container Apps environment](https://learn.microsoft.com/en-us/azure/container-apps/how-to-use-private-endpoint?pivots=azure-cli)

# Usage

## Deployment

1. Define some variables:

```bash
export RESOURCE_GROUP="my-resource-group"
export LOCATION="centralus"
```

1. Create a Resource Group:

```bash
az group create --location $LOCATION --name $RESOURCE_GROUP
```

1. Deploy the Bicep Template
If you want to change the name of any of the deployed resources, please edit the top of `main-mgd-net.bicep`. After you're satisfied, start the deployment.

```bash
az deployment group create --resource-group $RESOURCE_GROUP --template-file main-mgd-net.bicep
```
