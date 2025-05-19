FROM mcr.microsoft.com/azureml/minimal-py312-inference:latest

USER dockeruser

COPY azcopy-installer.sh /azcopy-installer.sh
COPY entrypoint.sh /entrypoint.sh

# Copy FastAPI app code and requirements file
WORKDIR /app
COPY app/ ./app/
COPY requirements.txt .

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    chmod +x /azcopy-installer.sh && \
    chmod +x /entrypoint.sh && \
    /azcopy-installer.sh && \
    mkdir /.azml_model_cache && \
    chmod 777 /.azml_model_cache && \
    chmod -R 777 /app

USER dockeruser

# Run entrypoint script to install dependencies and start the server
ENTRYPOINT [ "/entrypoint.sh" ]