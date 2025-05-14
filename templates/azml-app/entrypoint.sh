#!/bin/bash

echo "Azure Container App AI model server integration starting model server for model id: $AZURE_ML_MODEL_ID"

echo "Starting pip install for requirements.txt..."
pip install --no-cache-dir -r /app/requirements.txt --quiet

echo "Completed pip install. Starting model server..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000