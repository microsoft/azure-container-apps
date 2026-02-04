# URL Redirects for containerapps.io

This directory contains a lightweight NGINX-based redirect service deployed on Azure Container Apps. It handles HTTP redirects for various `*.containerapps.io` subdomains.

## How It Works

1. **redirects.yaml** - Simple configuration file listing all redirects
2. **Dockerfile** - Builds an NGINX container that reads the config
3. **GitHub Actions** - Automatically deploys on changes to `main`

## Adding a New Redirect

### Step 1: Update Configuration

Edit `redirects.yaml` and add your redirect:

```yaml
redirects:
  - host: your-subdomain.containerapps.io
    target: https://your-destination.com/path/
    preserve_path: false  # Set to true if you want to append the request path
```

### Step 2: Create a Pull Request

Submit a PR with your changes. The PR will be reviewed and merged.

### Step 3: Post-Merge Manual Steps

After the PR is merged and deployed, an admin needs to:

1. **Create DNS CNAME Record**
   ```
   your-subdomain.containerapps.io CNAME -> <container-app-fqdn>
   ```

2. **Add Custom Domain to Container App**
   ```bash
   az containerapp hostname add \
     --name url-redirects \
     --resource-group prodish-stuff \
     --hostname your-subdomain.containerapps.io
   ```

3. **Configure SSL Certificate** (managed certificate recommended)
   ```bash
   az containerapp hostname bind \
     --name url-redirects \
     --resource-group prodish-stuff \
     --hostname your-subdomain.containerapps.io \
     --environment <env-name> \
     --validation-method CNAME
   ```

## Configuration Options

| Field | Required | Description |
|-------|----------|-------------|
| `host` | Yes | The subdomain to redirect from (e.g., `start.containerapps.io`) |
| `target` | Yes | The destination URL (full URL with `https://`) |
| `preserve_path` | No | If `true`, appends the request path to the target URL. Default: `false` |

## Examples

**Simple redirect (most common):**
```yaml
- host: start.containerapps.io
  target: https://microsoft.github.io/azure-container-apps/aca-getting-started/
```
Result: `start.containerapps.io/anything` → `https://microsoft.github.io/azure-container-apps/aca-getting-started/`

**Path-preserving redirect:**
```yaml
- host: docs.containerapps.io
  target: https://learn.microsoft.com/azure/container-apps
  preserve_path: true
```
Result: `docs.containerapps.io/overview` → `https://learn.microsoft.com/azure/container-apps/overview`

## Local Testing

```bash
# Build the container
docker build -t url-redirects .

# Run locally
docker run -p 8080:80 url-redirects

# Test a redirect (will show 301 redirect)
curl -I -H "Host: start.containerapps.io" http://localhost:8080/

# Test health endpoint
curl http://localhost:8080/health
```

## Infrastructure

- **Resource Group:** `prodish-stuff`
- **Region:** Central US
- **Container App:** `url-redirects`
- **Container Registry:** Azure Container Registry (configured in GitHub Actions)

## Troubleshooting

**Redirect not working?**
1. Verify the CNAME record is properly configured
2. Check the custom domain is bound to the Container App
3. Ensure SSL certificate is provisioned and valid

**Getting 404?**
- The `Host` header doesn't match any configured redirect
- Check `redirects.yaml` for typos in the hostname
