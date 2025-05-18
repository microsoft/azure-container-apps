# Template to Deploy Azure AI Foundry Models to Azure Container Apps
This is the container template for deploying and hosting a Foundry Model on Azure Container Apps. This is also the source code of our MCR image that hosts our models.

## List of Blessed Models
[`azureml` Registry](https://ml.azure.com/registries/azureml/models):
- `Phi-4`
- `Phi-4-reasoning`
- `Phi-4-mini-reasoning`
- `Phi-3.5-mini-instruct`
- `GPT2-medium`
- `Mistralai-mistral-7b-v01`

Deploy the blessed models to a [serverless GPU location](https://aka.ms/aca/serverless-gpu-regions) using our provided MCR image by running the following command:
```
az containerapp up -n app-name -g resource-group-name -l gpu-location --environment your-env --model-registry azureml --model-name model-name --model-version version-number
```
You can then interact with your model by either visiting the /docs endpoint on your browser or sending POST request to /generate endpoint of your app.

## Guidance to Customization
### Deploying Models from `azureml` Model Registry
You can also download this template and modify it to suit other Azure AI Foundry models in `azureml` model registry.
Deploy the modified app to a [serverless GPU location](https://aka.ms/aca/serverless-gpu-regions) by building a docker image and pushing to a container registry and deploy to Azure Container Apps using
```
az containerapp up -n app-name -g resource-group-name -l gpu-location --environment your-env --image yourcontainerregistry.azurecr.io/repo:tag --model-registry azureml --model-name model-name --model-version version-number 
```
When specifying `--image` option, the CLI command will only attempt to help you setting the environment variables for downloading the model. You can modify all other variables by either hardcoding them in the score.py file or setting environment variables in your container app by passing `--env-vars "key=value"` or modify them in Azure Portal after your app is successfully deployed.

You will also need to manually set your ingress setting when using your customized image by providing `--ingress` and `--target-port` in `az containerapp up` command or running `az containerapp ingress` commands to further customize your ingress settings.

### Deploying Models from other registries
You can modify this template to your liking and deploy it like a normal Azure Container App by running `az containerapp up` or `az containerapp create`.

Learn more about `az containerapp` commands by visiting [az containerapp command documentation](https://learn.microsoft.com/en-us/cli/azure/containerapp?view=azure-cli-latest).

## Environment Variables Needed for Running with the given `entrypoint.sh`
| Env Vars | Required | Description| Example |
|---|---|---|---|
|`AZURE_ML_MODEL_ID` | `Yes` | Azure AI Foundry model asset id. | `azureml://registries/azureml/models/Phi-4/versions/7` |
|`AZURE_ML_MODEL_PATH` | `Yes` | Azure AI Foundry model asset uri. This is an Azure Storage Account URI. This will be automatically set when deploying using `az containerapp up` command with Foundry Integration options. | `N/A` |
| `AZURE_ML_MODEL_TYPE` | `No` | The type of model that is being deployed. If not specified, will default to `MLFLOW`. Currently only takes `MLFLOW`. This variable is case insensitive. | `MLFLOW` |
|`AZURE_ML_TOKENIZER_CLASS_NAME` | `Yes if model type is MLFLOW` | The class name used to load tokenizer. | `AutoTokenizer` |
| `AZURE_ML_PRETRAINED_MODEL_CLASS_NAME` | `Yes if model type is MLFLOW` | The class name used to load safetensor files and take inferencing requests. | `AutoModelForCausalLM` |
|`AZURE_ML_PIPELINE_INSTANCE_TYPE`| `No` | The pipeline class name. | `TextGenerationPipeline` |
|`AZURE_ML_PIPELINE_TASK_NAME` | `No` | The task type that the model is defined as. | `chat-completion`|


## File Structure of the Repo
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
