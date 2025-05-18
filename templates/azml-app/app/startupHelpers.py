import requests
import os
from xml.etree import ElementTree as et

from app.generateScore import ScoreFileGenerator


def get_model_details():
    """
    This function retrieves the model from Azure ML and returns the model and tokenizer.
    It uses the azcopy command to copy the model files from Azure Blob Storage to the local directory.
    """
    # Get the model id and path from environment variables
    model_id = os.environ["AZURE_ML_MODEL_ID"]
    model_path = os.environ["AZURE_ML_MODEL_PATH"]
    if model_path is None or model_id is None:
        raise ValueError("AZURE_ML_MODEL_PATH or AZURE_ML_MODEL_ID environment variable not set")
    res = requests.post("https://ml.azure.com/api/eastus/assetstore/v1.0/dataReference/getBlobReferenceSAS", json={"assetId": model_id, "blobUri": model_path}, timeout=15)
    if res.status_code != 200:
        raise ValueError(f"Failed to get blob reference: {res.status_code} {res.text}")
    res = res.json()
    if res["blobReferenceForConsumption"] is None:
        raise RuntimeError("Failed to retrieve blob reference from Azure ML. Exiting")
    sas_uri = res["blobReferenceForConsumption"]["credential"]["sasUri"]
    if sas_uri is None:
        raise ValueError(f"Failed to get source sas uri: {res.status_code} {res.text}")
    model_path = model_path.replace("https://", "")
    path_components = model_path.split("/")
    if len(path_components) < 2:
        raise ValueError("Failed to parse model path")
    model_dir_name = path_components[1]
    return sas_uri, model_dir_name


def get_model_file_structure(sas_uri):
    """
    This function retrieves the model and tokenizer from the blob list.
    It uses the azcopy command to copy the model files from Azure Blob Storage to the local directory.
    """
    # Get the model id and path from environment variables
    sas_list_uri = f"{sas_uri}&comp=list&restype=container"
    blob_list_res = requests.get(sas_list_uri)
    if blob_list_res.status_code != 200:
        raise ValueError(f"Failed to get blob list: {blob_list_res.status_code}")
    return et.fromstring(blob_list_res.content)


def set_score_file_generator_vars(sas_uri, model_dir_name, generator: ScoreFileGenerator):
    """
    This function detects the model asset path and tokenizer path from the blob list.
    """
    blob_list_xml = get_model_file_structure(sas_uri)
    # Detect model type
    generator.score_file_type = os.getenv("AZURE_ML_MODEL_TYPE")
    generator.model_dir_name = model_dir_name
    if generator.score_file_type is None or generator.score_file_type == "":
        print("AZURE_ML_MODEL_TYPE environment variable not set. Assuming default as mlflow")
    if generator.score_file_type.lower() == "mlflow":
        generator.score_file_type = "mlflow"
        for blob in blob_list_xml.findall(".//Blob"):
            blob_name = blob.find("Name").text
            if blob_name.endswith(".safetensors") and generator.model_asset_path is None:
                # remove the file name and only keep the path
                generator.model_asset_path = os.path.dirname(blob_name)
            if blob_name.endswith("tokenizer.json") and generator.tokenizer_path is None:
                # remove the file name and only keep the path
                generator.tokenizer_path = os.path.dirname(blob_name)
            if generator.model_asset_path is not None and generator.tokenizer_path is not None:
                break
        if generator.model_asset_path is None or generator.model_asset_path == "":
            raise ValueError("Failed to find model asset path")
        if generator.tokenizer_path is None or generator.tokenizer_path == "":
            raise ValueError("Failed to find tokenizer path")
        if generator.model_dir_name is None or generator.model_dir_name == "":
            raise ValueError("Failed to get local model directory name")
        generator.tokenizer_class_name = os.getenv("AZURE_ML_TOKENIZER_CLASS_NAME")
        if generator.tokenizer_class_name is None or generator.tokenizer_class_name == "":
            raise ValueError("AZURE_ML_TOKENIZER_CLASS_NAME environment variable not set")
        generator.model_loader_class_name = os.getenv("AZURE_ML_PRETRAINED_MODEL_CLASS_NAME")
        if generator.model_loader_class_name is None or generator.model_loader_class_name == "":
            raise ValueError("AZURE_ML_PRETRAINED_MODEL_CLASS_NAME environment variable not set")
        generator.pipeline_class_name = os.getenv("AZURE_ML_PIPELINE_INSTANCE_TYPE")
        generator.pipeline_task_name = os.getenv("AZURE_ML_PIPELINE_TASK_NAME")
        return
    else:
        raise ValueError(f"Invalid model type {generator.score_file_type}.")