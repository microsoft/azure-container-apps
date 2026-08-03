# ACA Region Discovery Script

Discovers which Azure Container Apps features are available in which Azure
regions using the **public Azure Retail Prices API** (no authentication
required). Generates reports in JSON, Markdown, and CSV formats for use by the
[Region Availability](../../aca-getting-started/region-availability.html) page.

## What It Checks

Availability is derived from the published per-region billing meters of the
`Azure Container Apps` service.

**Resource types:**
- `managedEnvironments` — Container Apps Environments
- `containerApps` — Container Apps
- `jobs` — Container App Jobs
- `sessionPools` — Dynamic Sessions (from the "Dynamic Sessions" meter)

**Plans / workload profiles:**
- Consumption (serverless, scale-to-zero) — from `Standard *` meters
- Dedicated workload profiles — from `Dedicated *` meters

  > Note: pricing meters do not distinguish individual dedicated profile sizes
  > (D4/D8/E16/…), so these are collapsed into a single **Dedicated**
  > capability.

**GPU SKUs** (differentiated per region):
- Consumption GPU — NC A100 v4
- Consumption GPU — NC T4 v3
- Dedicated GPU

**Infrastructure:**
- Availability Zone support — from a maintained static list
  ([source](https://learn.microsoft.com/azure/reliability/availability-zones-region-support)),
  since AZ support is not published through pricing data.

## Prerequisites

- Python 3.13+
- [uv](https://docs.astral.sh/uv/) for dependency management
- Outbound network access to `https://prices.azure.com` (no Azure credential
  or subscription required)

## Setup

```bash
cd scripts/region-discovery
uv sync
```

## Usage

### Full scan — JSON output (used by the GitHub Action)

```bash
uv run python discover.py --output-format json --output-dir ./output
```

This produces `output/region-features.json` — the file consumed by the
Region Availability page.

### Full scan — all formats

```bash
uv run python discover.py --output-dir ./output
```

Generates JSON, Markdown, and CSV reports in the output directory.

### List available regions only

```bash
uv run python discover.py --regions-only
```

### Scan specific regions

```bash
uv run python discover.py --regions eastus westeurope
```

### Check specific features

Features use a prefixed key format: `rt:` for resource types, `wp:` for
workload profiles / GPU, `az:` for availability zones.

```bash
uv run python discover.py --features rt:sessionPools wp:Consumption az:AvailabilityZones
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
  "data_source": "Azure Retail Prices API",
  "note": "Feature availability derived from public billing meters; dedicated profile sizes are collapsed into a single Dedicated capability.",
  "region_count": 58,
  "feature_count": 10,
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
        "wp:Dedicated": true
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
