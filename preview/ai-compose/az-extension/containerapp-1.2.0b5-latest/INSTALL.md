# Quick Installation Guide (generated 2025-11-16 22:00:46 UTC)

These wheels are staged for commit under:

- Release folder: preview/ai-compose/az-extension/release-1.2.0b5+ai.compose-py2.py3-none-any
- Latest alias: preview/ai-compose/az-extension/containerapp-1.2.0b5-latest
- Checksum file: preview/ai-compose/az-extension/release-1.2.0b5+ai.compose-py2.py3-none-any/MD5SUMS

## Quick Start – GitHub hosted release folder
PREVIEW_BASE=https://raw.githubusercontent.com/microsoft/azure-container-apps/main/preview/ai-compose/az-extension
DROP=release-1.2.0b5+ai.compose-py2.py3-none-any
PYCOMPOSE_WHEEL=pycomposefile-0.0.32-py3-none-any.whl
CONTAINERAPP_WHEEL=containerapp-1.2.0b5+ai.compose-py2.py3-none-any.whl

curl -s "https://raw.githubusercontent.com/microsoft/azure-container-apps/main/preview/ai-compose/az-extension/release-1.2.0b5+ai.compose-py2.py3-none-any/MD5SUMS"
az extension remove --name containerapp
pip install "https://raw.githubusercontent.com/microsoft/azure-container-apps/main/preview/ai-compose/az-extension/release-1.2.0b5+ai.compose-py2.py3-none-any/pycomposefile-0.0.32-py3-none-any.whl"
az extension add --source "https://raw.githubusercontent.com/microsoft/azure-container-apps/main/preview/ai-compose/az-extension/release-1.2.0b5+ai.compose-py2.py3-none-any/containerapp-1.2.0b5+ai.compose-py2.py3-none-any.whl" --yes
az extension show --name containerapp --query version -o tsv
az containerapp compose --help

## Option A – Existing Azure CLI (latest alias)
az extension remove --name containerapp
pip install "https://raw.githubusercontent.com/microsoft/azure-container-apps/main/preview/ai-compose/az-extension/containerapp-1.2.0b5-latest/pycomposefile-0.0.32-py3-none-any.whl"
az extension add --source "https://raw.githubusercontent.com/microsoft/azure-container-apps/main/preview/ai-compose/az-extension/containerapp-1.2.0b5-latest/containerapp-1.2.0b5+ai.compose-py2.py3-none-any.whl" --yes
az extension show --name containerapp --query version -o tsv
az containerapp compose --help

## Option B – Fresh virtual environment (release folder)
python3 -m venv ~/venv-containerapp && source ~/venv-containerapp/bin/activate
pip install --upgrade pip wheel azure-cli
pip install "https://raw.githubusercontent.com/microsoft/azure-container-apps/main/preview/ai-compose/az-extension/release-1.2.0b5+ai.compose-py2.py3-none-any/pycomposefile-0.0.32-py3-none-any.whl"
az extension add --source "https://raw.githubusercontent.com/microsoft/azure-container-apps/main/preview/ai-compose/az-extension/release-1.2.0b5+ai.compose-py2.py3-none-any/containerapp-1.2.0b5+ai.compose-py2.py3-none-any.whl" --yes
az containerapp compose --help

## Option C – Local release folder
az extension remove --name containerapp
pip install /home/simon/code/azure-agent-compose-project/cli/releases/release-1.2.0b5+ai.compose-py2.py3-none-any/pycomposefile-0.0.32-py3-none-any.whl
az extension add --source /home/simon/code/azure-agent-compose-project/cli/releases/release-1.2.0b5+ai.compose-py2.py3-none-any/containerapp-1.2.0b5+ai.compose-py2.py3-none-any.whl --yes
az containerapp compose --help
