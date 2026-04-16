# ACA Region Discovery Script

Discovers which Azure Container Apps features are available in which Azure
regions by querying the Azure ARM API. Generates reports in JSON, Markdown,
and CSV formats for use by the
[Region Availability](../../aca-getting-started/region-availability.html) page.

## What It Checks

**Resource types** (via Microsoft.App provider metadata):
- `managedEnvironments` — Container Apps Environments
- `containerApps` — Container Apps
- `jobs` — Container App Jobs
- `sessionPools` — Dynamic Sessions

**Workload profiles** (via the `availableManagedEnvironmentsWorkloadProfileTypes` API):
- Consumption (serverless, scale-to-zero)
- Dedicated general-purpose: D4, D8, D16, D32
- Dedicated memory-optimized: E4, E8, E16, E32
- GPU profiles: Consumption-GPU and NC-series variants
- Any other profiles discovered at runtime

**Infrastructure:**
- Availability Zone support

## Prerequisites

- Python 3.12+
- [uv](https://docs.astral.sh/uv/) for dependency management
- Azure CLI authenticated (`az login`) or another credential source supported
  by `DefaultAzureCredential`
- An Azure subscription ID with at least `Reader` access

## Setup

```bash
cd scripts/region-discovery
uv sync
```

## Usage

### Full scan — JSON output (used by the GitHub Action)

```bash
uv run python discover.py --subscription-id <SUBSCRIPTION_ID> --output-format json --output-dir ./output
```

This produces `output/region-features.json` — the file consumed by the
Region Availability page.

### Full scan — all formats

```bash
uv run python discover.py --subscription-id <SUBSCRIPTION_ID> --output-dir ./output
```

Generates JSON, Markdown, and CSV reports in the output directory.

### List available regions only

```bash
uv run python discover.py --subscription-id <SUBSCRIPTION_ID> --regions-only
```

### Scan specific regions

```bash
uv run python discover.py --subscription-id <SUBSCRIPTION_ID> --regions eastus westeurope
```

### Check specific features

Features use a prefixed key format: `rt:` for resource types, `wp:` for
workload profiles, `az:` for availability zones.

```bash
uv run python discover.py --subscription-id <SUBSCRIPTION_ID> --features rt:sessionPools wp:D4 az:AvailabilityZones
```

## Output Formats

| Format   | Filename                              | Description                          |
|----------|---------------------------------------|--------------------------------------|
| JSON     | `region-features.json`                | Structured data for the web page     |
| Markdown | `aca_region_features_YYYYMMDD_HHMMSS.md` | Human-readable table                |
| CSV      | `aca_region_features_YYYYMMDD_HHMMSS.csv` | For programmatic / spreadsheet use  |

### JSON Schema

```jsonc
{
  "schema_version": 1,
  "generated_at": "2026-04-10T15:57:19Z",
  "region_count": 40,
  "feature_count": 39,
  "features": [
    {
      "key": "rt:managedEnvironments",   // column key
      "name": "managedEnvironments",     // raw name
      "display_name": "Managed Environments",
      "category": "resource_type",       // resource_type | workload_profile | gpu | infrastructure
      "group": "Resource Types"          // UI grouping label
    }
  ],
  "regions": [
    {
      "slug": "eastus",
      "display_name": "East US",
      "features": {
        "rt:managedEnvironments": true,  // true = available, false = not available, null = unknown
        "wp:D4": false
      }
    }
  ]
}
```

## Automated Execution

This script runs daily via the
[Region Discovery GitHub Action](../../.github/workflows/region-discovery.yml).
The action commits updated JSON to `aca-getting-started/data/region-features.json`,
which is then deployed to GitHub Pages automatically.

## License

MIT
