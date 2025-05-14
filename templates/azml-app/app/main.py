from fastapi import FastAPI, Request
import os
import subprocess

from app.generateScore import ScoreFileGenerator
from app.startupHelpers import get_model_details, set_score_file_generator_vars

app = FastAPI()

# Global placeholders (will be initialized later)
tokenizer = None
model = None
pipe = None

# Serve out get traffic on root path ASAP, do not wait on model loading
@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI!"}

@app.get("/readiness", status_code=200)
def readiness():
    """
    Readiness probe for the application.
    """
    if tokenizer is None or model is None:
        return {"status": "tokenizer or model hasn't been loaded yet"}, 503
    return {"status": "ready"}, 200

@app.post("/generate")
async def generate(request: Request):
    import app.score as score
    res = await score.run(request, pipe, tokenizer, model)
    return res

# We expect model data to be loaded on a volume mounted at /.azml_model_cache
@app.on_event("startup")
async def load_model():
    global tokenizer, model, pipe
    generator = ScoreFileGenerator()
    sas_uri, model_download_path_name = get_model_details()
    if sas_uri is None:
        raise ValueError("Failed to get model download uri")
    print("Download model...")
    azcopy_process = subprocess.Popen(f"azcopy copy '{sas_uri}' '/.azml_model_cache/' --recursive=true",
                                      shell=True,
                                      stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE)
    azcopy_stdout, azcopy_stderr = azcopy_process.communicate()
    print(f"azcopy stdout: {azcopy_stdout.decode()}")
    print(f"azcopy stderr: {azcopy_stderr.decode()}")
    print("Setting score file generator vars...")
    set_score_file_generator_vars(sas_uri,
                                  model_download_path_name,
                                  generator)
    generator.generate()
    if azcopy_process.returncode != 0:
        raise RuntimeError(f"azcopy failed with return code {azcopy_process.returncode}")
    from app.score import init
    pipe, model, tokenizer = init()
    print("Model loaded. Ready to take inferencing requests under path /generate")
