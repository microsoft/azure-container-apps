import os

SCORE_FILE_TEMPLATE = """from fastapi import Request
from transformers import TOKENIZER_TYPE, MODEL_TYPE
IMPORT_PIPELINE_TYPE
import os

def init():
    pipe = None
    model = None
    tokenizer = None
    print("Loading model...")
    model = MODEL_TYPE.from_pretrained(f"SAFETENSOR_PATH", local_files_only=True)
    print("Loading tokenizer...")
    tokenizer = TOKENIZER_TYPE.from_pretrained(f"TOKENIZER_PATH", local_files_only=True)
    PIPELINE_LOADING
    return pipe, model, tokenizer

async def run(request, pipe, tokenizer, model):
    if pipe is not None:
        body = await request.json()
        prompt = body.get("prompt", "")
        output = pipe(prompt, max_new_tokens=100)
        result = output[0]["generated_text"]
        return result
    if model is not None and tokenizer is not None:
        body = await request.json()
        prompt = body.get("prompt", "")
        inputs = tokenizer(prompt, return_tensors="pt")
        output = model.generate(**inputs, max_new_tokens=100)
        result = tokenizer.decode(output[0], skip_special_tokens=True)
        return {"response": result}
    else:
        print("Error: Model not loaded yet")
        return {"error": "Model not loaded yet"}

"""
IMPORT_PIPELINE_TYPE = """from transformers import PIPELINE_TYPE"""
PIPELINE_LOADING_TEMPLATE = """print("Constructing pipeline...")
    pipe = PIPELINE_TYPE(TASK_NAMEmodel=model, tokenizer=tokenizer)"""
KNOWN_TASK_PIPELINE_MAP = {
    "chat-completion": "TextGenerationPipeline",
}
SCORE_FILE_TEMPLATE_ONNX = """from fastapi import Request
import onnxruntime
import sys
import os

def init():
    session = onnxruntime.InferenceSession("ONNX_PATH", providers=["CUDAExecutionProvider"])
    return session, None, None


async def run(request, session, tokenizer_placeholder=None, model_placeholder=None):
    if session is None:
        sys.stderr.write("Error: Session not loaded yet")
        sys.stderr.flush()
        return {"error": "Session not loaded yet"}

    body = await request.json()
    prompt = body.get("prompt", "")
    output = session.run_async(None, {session.get_inputs()[0].name, prompt})
    result = output[0]
    return {result}
"""


class ScoreFileGenerator:
    def __init__(self, model_dir_name: str = None, pipeline_class_name: str = None, tokenizer_class_name: str = None,
                 model_loader_class_name: str = None, pipeline_task_name: str = None, tokenizer_path: str = None,
                 model_asset_path: str = None):
        """
            Generates a score file for the model.
            :param model_dir_name: The name of the model directory.
            :param pipeline_type_name: The type of the pipeline.
            :param tokenizer_type_name: The type of the tokenizer.
            :param model_loader_type_name: The type of the model loader.
            :param pipeline_task_name: The task name for the pipeline.
            :param tokenizer_path: The path to the tokenizer.
            :param model_asset_path: The path to the safetensor files.
        """
        self.model_dir_name = model_dir_name
        self.pipeline_class_name = pipeline_class_name
        self.tokenizer_class_name = tokenizer_class_name
        self.model_loader_class_name = model_loader_class_name
        self.pipeline_task_name = pipeline_task_name
        self.tokenizer_path = tokenizer_path
        self.model_asset_path = model_asset_path

        self.score_file_type = None

    def generate(self):
        print("Generating score file...")
        if self.score_file_type.lower() == "mlflow":
            return self.generate_score_file_mlflow()
        elif self.score_file_type.lower() == "custom":
            return self.generate_score_file_onnx()
        else:
            raise ValueError("Invalid model type.")

    def generate_score_file_mlflow(self):
        pipeline_import_template = ""
        pipeline_loading_template = ""
        if self.pipeline_task_name is not None and self.pipeline_task_name != "":
            pipeline_loading_template = \
                PIPELINE_LOADING_TEMPLATE \
                .replace("TASK_NAME", f"task=\"{self.pipeline_task_name}\", ")
            if self.pipeline_class_name is None and KNOWN_TASK_PIPELINE_MAP[self.pipeline_task_name] is not None:
                self.pipeline_class_name = KNOWN_TASK_PIPELINE_MAP[self.pipeline_task_name]
        else:
            pipeline_loading_template = \
                PIPELINE_LOADING_TEMPLATE \
                .replace("TASK_NAME", "")

        if self.pipeline_class_name is not None and self.pipeline_class_name != "":
            pipeline_import_template = \
                IMPORT_PIPELINE_TYPE \
                .replace("PIPELINE_TYPE", self.pipeline_class_name)
            pipeline_loading_template = \
                pipeline_loading_template \
                .replace("PIPELINE_TYPE", self.pipeline_class_name)
        template = \
            SCORE_FILE_TEMPLATE \
            .replace("IMPORT_PIPELINE_TYPE", pipeline_import_template) \
            .replace("PIPELINE_LOADING", pipeline_loading_template) \
            .replace("TOKENIZER_TYPE", self.tokenizer_class_name) \
            .replace("MODEL_TYPE", self.model_loader_class_name) \
            .replace("TOKENIZER_PATH", f"/.azml_model_cache/{self.model_dir_name}/{self.tokenizer_path}") \
            .replace("SAFETENSOR_PATH", f"/.azml_model_cache/{self.model_dir_name}/{self.model_asset_path}")
        try:
            with open("/app/app/score.py", "w") as f:
                f.write(template)
            print("Score file generated successfully.")
        except Exception as e:
            raise RuntimeError("Error generating score file") from e

    def generate_score_file_onnx(self):
        template = \
            SCORE_FILE_TEMPLATE_ONNX \
            .replace("ONNX_PATH", f"/.azml_model_cache/{self.model_dir_name}/{self.model_asset_path}")
        try:
            with open("/app/app/score.py", "w") as f:
                f.write(template)
            print("Score file generated successfully.")
        except Exception as e:
            raise RuntimeError("Error generating score file") from e
