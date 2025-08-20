# Azure ML Container App Python Frontend

This directory contains the Python application code for serving machine learning models in Azure Container Apps. The application is designed to dynamically generate a scoring script (`score.py`) based on model-specific settings and serve inference requests using FastAPI.

## File Overview

### [`main.py`](main.py)
- **Purpose:** Entry point for the FastAPI server. Handles HTTP endpoints for health checks and inference, and manages model loading at startup.
- **Key Functions:**
  - **Startup Event:** On server startup, triggers the model download, dynamic score file generation, and model/tokenizer loading.
  - **Endpoints:**
    - `/`: Root endpoint for a simple health message.
    - `/readiness`: Readiness probe to check if the model and tokenizer are loaded.
    - `/generate`: POST endpoint for inference requests, which delegates to the dynamically generated `score.py`.

### [`startupHelpers.py`](startupHelpers.py)
- **Purpose:** Contains helper functions for retrieving model details from Azure ML, parsing blob storage, and configuring the score file generator.
- **Key Functions:**
  - `get_model_details()`: Uses environment variables to request a SAS URI for the model from Azure ML, and parses the model directory name.
  - `get_model_file_structure(sas_uri)`: Lists blobs in the model storage container to identify model and tokenizer files.
  - `set_score_file_generator_vars(...)`: Inspects the blob structure and environment variables to configure the [`ScoreFileGenerator`](generateScore.py) with the correct paths and class names for the model, tokenizer, and pipeline.

### [`generateScore.py`](generateScore.py)
- **Purpose:** Implements the [`ScoreFileGenerator`](generateScore.py) class, which dynamically generates a `score.py` file tailored to the specific model and settings.
- **Key Components:**
  - **Templates:** Contains string templates for the scoring script, pipeline imports, and pipeline construction.
  - **ScoreFileGenerator:** Class that, when configured, writes a `score.py` file with the correct model/tokenizer loading and inference logic based on environment variables and blob storage structure.
  - **Model Type Handling:** Supports different model types (e.g., MLFLOW, CUSTOM) and adapts the generated code accordingly.

## How the Application Loads the Model

### 1. **Startup Sequence in [`main.py`](main.py)**
- On FastAPI startup (`@app.on_event("startup")`), the following steps occur:
  1. **Model Details Retrieval:** Calls [`get_model_details()`](startupHelpers.py) to obtain the SAS URI for the model files and the model directory name.
  2. **Model Download:** Uses `azcopy` to download all model files from Azure Blob Storage to the local cache directory (`/.azml_model_cache/`).
  3. **Score File Generation:**
     - Instantiates a [`ScoreFileGenerator`](generateScore.py).
     - Calls [`set_score_file_generator_vars()`](startupHelpers.py) to configure the generator with the correct paths and class names, based on blob contents and environment variables.
     - Calls `generator.generate()` to write a new `score.py` file in the app directory, customized for the current model.
  4. **Model and Tokenizer Loading:** Imports the `init()` function from the newly generated `score.py` and calls it to load the model, tokenizer, and (optionally) pipeline into memory.
  5. **Ready for Requests:** The server is now ready to handle inference requests at the `/generate` endpoint.

### 2. **Dynamic Score File Generation**
- The [`ScoreFileGenerator`](generateScore.py) uses:
  - **Blob Storage Inspection:** Determines the correct paths for model weights and tokenizer files.
  - **Environment Variables:** Reads variables such as `AZURE_ML_MODEL_TYPE`, `AZURE_ML_TOKENIZER_CLASS_NAME`, `AZURE_ML_PRETRAINED_MODEL_CLASS_NAME`, and others to select the appropriate classes and pipeline types.
  - **Template Substitution:** Fills in the scoring script template with the discovered paths and class names, ensuring that the inference logic matches the model's requirements.
- The generated [`score.py`](score.py) is then used by the FastAPI app for all inference requests.
