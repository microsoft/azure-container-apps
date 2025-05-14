FROM mcr.microsoft.com/azureml/minimal-py312-inference:latest

USER root

RUN apt-get update && apt-get install -y --no-install-recommends curl

# Copy azcopy installation script and run it.
COPY azcopy-installer.sh /azcopy-installer.sh
RUN chmod +x /azcopy-installer.sh
RUN /azcopy-installer.sh

# Set working directory
WORKDIR /app

RUN mkdir /.azml_model_cache

# Copy FastAPI app code
COPY app/ ./app/
COPY requirements.txt .

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Run entrypoint script to install dependencies and start the server
ENTRYPOINT [ "/entrypoint.sh" ]