# Template to deploy Azure AI Foundry Models to Azure Container Apps
This is the container template for deploying and hosting a Foundry Model on Azure Container Apps. This is also the source code of our MCR image that hosts our models.

## Deploying models
For models listed here, you can deploy them directly to Azure Container Apps serverless GPUs without needing to build your own image by using the below CLI command:

```
az containerapp up -n app-name -g resource-group-name -l gpu-location --environment your-env --model-registry azureml --model-name model-name --model-version version-number
```

For models not in this list, you will also need to specify the --image tag and follow additional steps in [Guidance to customization](https://github.com/microsoft/azure-container-apps/blob/d57bb0f924bc99234e3cbcde407af0f1508baf59/templates/azml-app/README.md#guidance-to-customization)

[Models from `azureml` Registry](https://ml.azure.com/registries/azureml/models):
- `Phi-4`
- `Phi-4-reasoning`
- `Phi-4-mini-reasoning`
- `Phi-3.5-mini-instruct`
- `GPT2-medium`
- `Mistralai-mistral-7b-v01`

You can then interact with your model by either visiting the /docs endpoint for your deployed container app or sending a POST request to the /generate endpoint of your app.

## Guidance to customization

### Deploying additional models from `azureml` Model Registry
You can also download this template and modify it to deploy other Azure AI Foundry models in the `azureml` model registry.

To do so, you will need to:

1. Download this github template for the model image from the [Azure Container Apps repo](https://github.com/microsoft/azure-container-apps/tree/main/templates/azml-app).

1. Modify the score.py file to match your model type. The scoring script (named *score.py*) defines how you interact with the model. The following example shows [how to use a custom score.py file](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-online-endpoints?view=azureml-api-2&tabs=cli#understand-the-scoring-script).

1. Make any other modifications to the Dockerfile, entrypoint.sh, or any other files in the template as needed for your model.

1. Build the image and deploy it to a container registry.

1. Use the below CLI command to deploy the model to serverless GPUs, but specify the `--image`. By using the `--model-registry`, `--model-name`, and `--model-version` parameters, the key environment variables are set for you to optimize cold start for your app.

```
az containerapp up -n app-name -g resource-group-name -l gpu-location --environment your-env --image yourcontainerregistry.azurecr.io/repo:tag --model-registry azureml --model-name model-name --model-version version-number 
```

You will also need to manually set your ingress setting when using your customized image by providing `--ingress` and `--target-port` in `az containerapp up` command or running `az containerapp ingress` commands to further customize your ingress settings.

### Deploying models from other registries
You can modify this template to deploy it like a normal Azure Container App by running `az containerapp up` or `az containerapp create`.

Learn more about `az containerapp` commands by visiting [az containerapp command documentation](https://learn.microsoft.com/en-us/cli/azure/containerapp?view=azure-cli-latest).

## Environment variables needed for running with the given `entrypoint.sh`
| Env Vars | Required | Description| Example |
|---|---|---|---|
|`AZURE_ML_MODEL_ID` | `Yes` | Azure AI Foundry model asset id. | `azureml://registries/azureml/models/Phi-4/versions/7` |
|`AZURE_ML_MODEL_PATH` | `Yes` | Azure AI Foundry model asset uri. This is an Azure Storage Account URI. This will be automatically set when deploying using `az containerapp up` command with Foundry Integration options. | `N/A` |
| `AZURE_ML_MODEL_TYPE` | `No` | The type of model that is being deployed. If not specified, will default to `MLFLOW`. Currently only takes `MLFLOW`. This variable is case insensitive. | `MLFLOW` |
|`AZURE_ML_TOKENIZER_CLASS_NAME` | `Yes if model type is MLFLOW` | The class name used to load tokenizer. | `AutoTokenizer` |
| `AZURE_ML_PRETRAINED_MODEL_CLASS_NAME` | `Yes if model type is MLFLOW` | The class name used to load safetensor files and take inferencing requests. | `AutoModelForCausalLM` |
|`AZURE_ML_PIPELINE_INSTANCE_TYPE`| `No` | The pipeline class name. | `TextGenerationPipeline` |
|`AZURE_ML_PIPELINE_TASK_NAME` | `No` | The task type that the model is defined as. | `chat-completion`|


## File structure of the repo
```
├── app/
│   ├── main.py                
|   |   # FastAPI application for serving model inference requests.
|   ├── generateScore.py
|   |   # Dynamically generate a score.py file
|   ├── startupHelpers.py
|   |   # Helper functions that get invoked during server startup.
|   ├── inferenceClasses.py
|   |   # Request and response classes definition for inference endpoint.
|   └── README.md
|       # Documentation of the Python frontend app.
├── requirements.txt
|   # Python dependencies for the FastAPI app.
├── azcopy-installer.sh
|   # Script to install AzCopy for efficient file transfers.
├── Dockerfile
|   # A very basic runtime image for inferencing app runtime.
├── entrypoint.sh
|   # Entrypoint script for the container that first download required Python packages and then start the frontend app.
└── README.md
    # The README you're currently reading.
```
