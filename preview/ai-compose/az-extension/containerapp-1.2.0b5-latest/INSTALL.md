# Quick Installation Guide (generated 2025-11-16 22:00:46 UTC)

These wheels live in your local Azure Container Apps preview repo checkout:

- Location: `~./azure-container-apps/preview/ai-compose/az-extension/containerapp-1.2.0b5-latest`
- Files staged for commit: `containerapp-1.2.0b5+ai.compose-py2.py3-none-any.whl`, `pycomposefile-0.0.32-py3-none-any.whl`, `MD5SUMS`, `INSTALL.md`, `RELEASE_NOTES.md`
- Verification: `git status` in `preview/ai-compose/az-extension` shows the exact files above under "Changes to be committed"

## Quick Start – (use existing az cli, install from GH)
```bash
PREVIEW_BASE=https://raw.githubusercontent.com/microsoft/azure-container-apps/main/preview/ai-compose/az-extension
DROP=release-1.2.0b5+ai.compose-py2.py3-none-any

az extension remove --name containerapp
pip install "$PREVIEW_BASE/$DROP/pycomposefile-0.0.32-py3-none-any.whl"
az extension add --source "$PREVIEW_BASE/$DROP/containerapp-1.2.0b5+ai.compose-py2.py3-none-any.whl" --yes
az containerapp compose --help
```



## Option B – Isolated testing (venv + remote install)
Spin up a clean virtual environment that only contains what's needed for compose testing.
```bash
PREVIEW_BASE=https://raw.githubusercontent.com/microsoft/azure-container-apps/main/preview/ai-compose/az-extension
DROP=release-1.2.0b5+ai.compose-py2.py3-none-any

# install and create venv module
pip install venv
python3 -m venv ~/venv-containerapp && source ~/venv-containerapp/bin/activate

# install & create azure-cli and other requirements
pip install --upgrade pip wheel azure-cli

# install pycomposefile module and az-containerapp-ext
pip install "$PREVIEW_BASE/$DROP/pycomposefile-0.0.32-py3-none-any.whl"
az extension add --source "$PREVIEW_BASE/$DROP/containerapp-1.2.0b5+ai.compose-py2.py3-none-any.whl" --yes

# try compose sub-command
az containerapp compose --help

```