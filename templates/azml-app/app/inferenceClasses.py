from pydantic import BaseModel


class InferenceRequest(BaseModel):
    """
    Request object for inference requests.
    """
    prompt: str = None
    max_output_tokens: int = 1024


class InferenceResponse(BaseModel):
    """
    Response object for inference requests.
    """
    response: str = None
