# Template to Deploy Foundry Models to Azure Container Apps
This is the container template for deploying and hosting a Foundry Model on Azure Container Apps. This is also the source code of our MCR image that hosts our models.

## Environment Variables Needed for Running with the given `entrypoint.sh`
| Env Vars | Required | Description| Example |
|---|---|---|---|
|`AZURE_ML_MODEL_ID` | `Yes` | Foundry model asset id. | `azureml://registries/azureml/models/Phi-4/versions/7` |
|`AZURE_ML_MODEL_PATH` | `Yes` | Foundry model asset uri. This is an Azure Storage Account URI. This will be automatically set when deploying using `az containerapp up` command with Foundry Integration options. | `N/A` |
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
