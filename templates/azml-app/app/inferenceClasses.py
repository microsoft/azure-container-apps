from pydantic import BaseModel


class InferenceRequest(BaseModel):
    """
    Request object for inference requests.
    """
    prompt: str = None


class InferenceResponse(BaseModel):
    """
    Response object for inference requests.
    """
    response: str = None
