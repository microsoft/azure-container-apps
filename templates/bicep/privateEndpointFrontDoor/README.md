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


2. Create a resource group of your choosing:
   
```bash
az group create --location $LOCATION --name $RESOURCE_GROUP
```


3. Deploy the Bicep
If you want to change any of the names for any of the deployed resources please edit the top of `main-mgd-net.bicep`. After you're satisfied we start the deployment.

```bash
az deployment group create --resource-group $RESOURCE_GROUP --template-file main-mgd-net.bicep
```


## Approving the Connection

As the last step you have to approve the private endpoint from AFD into ACA. This can be done by following first [listing your private endpoint](https://learn.microsoft.com/en-us/azure/container-apps/how-to-integrate-with-azure-front-door#list-private-endpoint-connections) connections, and then [approving them](https://learn.microsoft.com/en-us/azure/container-apps/how-to-integrate-with-azure-front-door#approve-the-private-endpoint-connection).

```bash
export ENVIRONMENT_NAME=mycontainerappenv # Assuming names are kept as they are in the Bicep file


az network private-endpoint-connection list \
    --name $ENVIRONMENT_NAME \
    --resource-group $RESOURCE_GROUP \
    --type Microsoft.App/managedEnvironments

# Record the private endpoint connection resource ID from the response. Don't confuse this with the private endpoint ID. Replace the <PLACEHOLDER> with the private endpoint connection resource ID.
az network private-endpoint-connection approve --id <PRIVATE_ENDPOINT_CONNECTION_RESOURCE_ID>
```


# NOTES

* Not all warnings have been eliminated in this Bicep
* The connection approval is still manual, PRs welcome
