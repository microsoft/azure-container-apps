#!/usr/bin/env python3
"""Azure Container Apps Region Features Discovery Script.

Discovers which Azure Container Apps features are available in which Azure
regions using the **public Azure Retail Prices API** (no authentication
required) and generates reports in JSON, Markdown and CSV format.

Why the Retail Prices API?
    The previous implementation queried the ARM control plane
    (``Microsoft.App`` provider metadata) which requires an authenticated
    Azure credential. That credential is no longer available, so this script
    derives availability from the published per-region billing meters of the
    "Azure Container Apps" service, which are exposed anonymously at
    https://prices.azure.com/api/retail/prices.

Granularity note:
    Billing meters distinguish the *Consumption* plan, *Dedicated* workload
    profiles and the individual *GPU* SKUs, but they do not expose the
    specific dedicated profile sizes (D4/D8/E16/...). Those are therefore
    collapsed into a single "Dedicated" capability. Availability-Zone support
    is not published through pricing and is sourced from a maintained static
    list (see ``_AVAILABILITY_ZONE_REGIONS``).
"""

import argparse
import csv
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import requests as _requests


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

RETAIL_PRICES_API = "https://prices.azure.com/api/retail/prices"
RETAIL_PRICES_API_VERSION = "2023-01-01-preview"
ACA_SERVICE_NAME = "Azure Container Apps"

# Resource types whose per-region availability we report.
RESOURCE_TYPES = [
    "managedEnvironments",
    "containerApps",
    "jobs",
    "sessionPools",
]

# Region slug prefixes for sovereign / air-gapped clouds we exclude from the
# public commercial availability view.
_SOVEREIGN_PREFIXES = ("usgov", "usdod", "china", "deloscloud")

# GPU billing meter name -> feature key suffix (under the "wp:" namespace).
# Order here defines column order for GPU features.
_GPU_METER_MAP: dict[str, str] = {
    "Standard NC A100 v4 GPU Usage": "Consumption-GPU-A100",
    "Standard NC T4 v3 GPU Usage": "Consumption-GPU-T4",
    "Dedicated GPU Usage": "Dedicated-GPU",
}

# Azure regions with Availability Zone support. Pricing data does not expose
# AZ support, so this is a maintained static list.
# Source: https://learn.microsoft.com/azure/reliability/availability-zones-region-support
_AVAILABILITY_ZONE_REGIONS: set[str] = {
    # Americas
    "brazilsouth", "canadacentral", "centralus", "eastus", "eastus2",
    "mexicocentral", "southcentralus", "westus2", "westus3",
    # Europe
    "francecentral", "germanywestcentral", "italynorth", "northeurope",
    "norwayeast", "polandcentral", "spaincentral", "swedencentral",
    "switzerlandnorth", "uksouth", "westeurope",
    # Asia Pacific
    "australiaeast", "centralindia", "eastasia", "japaneast", "japanwest",
    "koreacentral", "newzealandnorth", "southeastasia",
    # Middle East & Africa
    "israelcentral", "qatarcentral", "southafricanorth", "uaenorth",
}

# Well-known Azure region slug -> display name mapping.
_REGION_DISPLAY_NAMES: dict[str, str] = {
    # Americas
    "eastus": "East US",
    "eastus2": "East US 2",
    "eastus2euap": "East US 2 EUAP",
    "centralus": "Central US",
    "centraluseuap": "Central US EUAP",
    "westus": "West US",
    "westus2": "West US 2",
    "westus3": "West US 3",
    "northcentralus": "North Central US",
    "southcentralus": "South Central US",
    "westcentralus": "West Central US",
    "canadacentral": "Canada Central",
    "canadaeast": "Canada East",
    "brazilsouth": "Brazil South",
    "brazilsoutheast": "Brazil Southeast",
    "mexicocentral": "Mexico Central",
    "chilecentral": "Chile Central",
    # Europe
    "northeurope": "North Europe",
    "westeurope": "West Europe",
    "uksouth": "UK South",
    "ukwest": "UK West",
    "francecentral": "France Central",
    "francesouth": "France South",
    "germanywestcentral": "Germany West Central",
    "germanynorth": "Germany North",
    "norwayeast": "Norway East",
    "norwaywest": "Norway West",
    "swedencentral": "Sweden Central",
    "swedensouth": "Sweden South",
    "switzerlandnorth": "Switzerland North",
    "switzerlandwest": "Switzerland West",
    "polandcentral": "Poland Central",
    "italynorth": "Italy North",
    "spaincentral": "Spain Central",
    "austriaeast": "Austria East",
    "belgiumcentral": "Belgium Central",
    "denmarkeast": "Denmark East",
    "finlandcentral": "Finland Central",
    "greececentral": "Greece Central",
    # Asia Pacific
    "eastasia": "East Asia",
    "southeastasia": "Southeast Asia",
    "japaneast": "Japan East",
    "japanwest": "Japan West",
    "australiaeast": "Australia East",
    "australiasoutheast": "Australia Southeast",
    "australiacentral": "Australia Central",
    "australiacentral2": "Australia Central 2",
    "koreacentral": "Korea Central",
    "koreasouth": "Korea South",
    "centralindia": "Central India",
    "southindia": "South India",
    "westindia": "West India",
    "jioindiawest": "Jio India West",
    "jioindiacentral": "Jio India Central",
    "newzealandnorth": "New Zealand North",
    "indonesiacentral": "Indonesia Central",
    "malaysiawest": "Malaysia West",
    "taiwannorth": "Taiwan North",
    "taiwannorthwest": "Taiwan Northwest",
    # Middle East & Africa
    "uaenorth": "UAE North",
    "uaecentral": "UAE Central",
    "southafricanorth": "South Africa North",
    "southafricawest": "South Africa West",
    "qatarcentral": "Qatar Central",
    "israelcentral": "Israel Central",
    "saudiarabiacentral": "Saudi Arabia Central",
    # Government / Sovereign
    "usgovvirginia": "US Gov Virginia",
    "usgovarizona": "US Gov Arizona",
    "usgovtexas": "US Gov Texas",
    "usdodcentral": "US DoD Central",
    "usdodeast": "US DoD East",
    "chinanorth": "China North",
    "chinanorth2": "China North 2",
    "chinanorth3": "China North 3",
    "chinaeast": "China East",
    "chinaeast2": "China East 2",
    "chinaeast3": "China East 3",
}

# Pattern to split a region slug into words for a best-effort display name.
_REGION_WORD_PATTERN = re.compile(
    r"(north|south|east|west|central|southeast|northwest|northeast|southwest|"
    r"us|uk|uae|jio|dod|gov|euap|india|china|korea|japan|australia|brazil|"
    r"canada|france|germany|norway|sweden|switzerland|poland|italy|spain|"
    r"qatar|israel|saudi|arabia|africa|europe|asia|zealand|mexico|indonesia|"
    r"malaysia|taiwan|austria|belgium|denmark|finland|greece|chile|\d+)",
    re.IGNORECASE,
)


# ---------------------------------------------------------------------------
# Helpers – display names
# ---------------------------------------------------------------------------

def _region_display_name(slug: str) -> str:
    """Convert a region slug to a human-readable display name."""
    if slug in _REGION_DISPLAY_NAMES:
        return _REGION_DISPLAY_NAMES[slug]

    words = _REGION_WORD_PATTERN.findall(slug)
    if words:
        return " ".join(w.capitalize() if not w.isupper() else w for w in words)
    return slug.title()


def _camel_to_display(name: str) -> str:
    """Insert spaces before uppercase letters in camelCase/PascalCase names.

    'managedEnvironments' -> 'Managed Environments'
    'AvailabilityZones'   -> 'Availability Zones'
    """
    spaced = re.sub(r"([a-z])([A-Z])", r"\1 \2", name)
    spaced = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1 \2", spaced)
    return spaced[:1].upper() + spaced[1:]


def _feature_display_name(col: str) -> str:
    """Return a human-readable display name for a feature column key."""
    kind, name = col.split(":", 1)
    if kind == "rt":
        return _camel_to_display(name)
    if kind == "az":
        return _camel_to_display(name)
    # Workload profiles / GPU SKUs: keep the descriptive name as-is.
    return name


# ---------------------------------------------------------------------------
# Helpers – feature categorization
# ---------------------------------------------------------------------------

def _categorize_feature(col: str) -> tuple[str, str]:
    """Return (category, group) for a feature column key."""
    kind, name = col.split(":", 1)
    if kind == "rt":
        return "resource_type", "Resource Types"
    if kind == "az":
        return "infrastructure", "Infrastructure"
    if kind == "wp":
        if "GPU" in name.upper():
            return "gpu", "GPU Profiles"
        if name == "Consumption":
            return "workload_profile", "Workload Profiles"
        # Dedicated workload profiles.
        return "workload_profile", "Dedicated Profiles"
    return "other", "Other"


# ---------------------------------------------------------------------------
# Data acquisition – public Azure Retail Prices API
# ---------------------------------------------------------------------------

def fetch_aca_price_items(timeout: int = 60) -> list[dict]:
    """Return all Retail Prices API items for the Azure Container Apps service.

    The endpoint is anonymous (no authentication) and paginates through
    ``NextPageLink``.
    """
    items: list[dict] = []
    url: str | None = RETAIL_PRICES_API
    params: dict | None = {
        "$filter": f"serviceName eq '{ACA_SERVICE_NAME}'",
        "api-version": RETAIL_PRICES_API_VERSION,
    }
    while url:
        resp = _requests.get(url, params=params, timeout=timeout)
        resp.raise_for_status()
        data = resp.json()
        items.extend(data.get("Items", []))
        url = data.get("NextPageLink")
        params = None  # NextPageLink already carries the query string
    return items


def build_region_meters(items: list[dict]) -> dict[str, set[str]]:
    """Group meter names by commercial region slug.

    Sovereign / air-gapped clouds and regions that only have "Hybrid" (Azure
    Arc) meters are excluded so the matrix reflects real commercial Azure
    regions where Container Apps is offered.
    """
    region_meters: dict[str, set[str]] = {}
    for item in items:
        slug = (item.get("armRegionName") or "").strip()
        if not slug or slug.startswith(_SOVEREIGN_PREFIXES):
            continue
        meter = item.get("meterName") or ""
        region_meters.setdefault(slug, set()).add(meter)

    # Drop regions that only carry Hybrid (Arc-connected) meters.
    return {
        slug: meters
        for slug, meters in region_meters.items()
        if any("Hybrid" not in m for m in meters)
    }


# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

def _gpu_feature_columns(all_meters: set[str]) -> list[tuple[str, str]]:
    """Return ordered (column_key, meter_name) pairs for GPU features present."""
    gpu_cols: list[tuple[str, str]] = []
    seen: set[str] = set()
    # Known GPU meters first, in defined order.
    for meter, suffix in _GPU_METER_MAP.items():
        if meter in all_meters:
            gpu_cols.append((f"wp:{suffix}", meter))
            seen.add(meter)
    # Any other GPU meter discovered at runtime.
    for meter in sorted(all_meters):
        if "GPU" in meter and meter not in seen:
            suffix = re.sub(r"\s+", "-", meter.replace(" Usage", "").strip())
            gpu_cols.append((f"wp:{suffix}", meter))
    return gpu_cols


def discover(
    regions: list[str] | None = None,
    features: list[str] | None = None,
) -> tuple[list[str], list[str], list[dict]]:
    """Run discovery from public pricing data.

    Returns (feature_columns, region_slugs, rows) where each row is a dict:
    {"region": slug, feature_key: bool, ...}.
    """
    print("Fetching Azure Container Apps pricing meters (public API) ...")
    items = fetch_aca_price_items()
    region_meters = build_region_meters(items)

    all_region_slugs = sorted(region_meters)
    if not all_region_slugs:
        print("  Error: no Container Apps pricing data returned.", file=sys.stderr)
        sys.exit(1)

    if regions:
        wanted = {r.replace(" ", "").lower() for r in regions}
        region_slugs = [s for s in all_region_slugs if s in wanted]
        if not region_slugs:
            print(
                f"  Warning: none of the requested regions matched. "
                f"Available: {all_region_slugs[:10]} ...",
                file=sys.stderr,
            )
            sys.exit(1)
    else:
        region_slugs = all_region_slugs

    all_meters: set[str] = set()
    for meters in region_meters.values():
        all_meters.update(meters)

    # ----- Build the feature column list -----
    feature_columns: list[str] = []

    # 1) Resource types.
    for rt in RESOURCE_TYPES:
        feature_columns.append(f"rt:{rt}")

    # 2) Plans / workload profiles (collapsed — see module docstring).
    feature_columns.append("wp:Consumption")
    feature_columns.append("wp:Dedicated")

    # 3) GPU SKUs (per-region differentiated by pricing).
    gpu_cols = _gpu_feature_columns(all_meters)
    feature_columns.extend(key for key, _ in gpu_cols)

    # 4) Availability Zones (static list).
    feature_columns.append("az:AvailabilityZones")

    # Optional --features filter (accepts prefixed keys or short names).
    if features:
        def _wanted(col: str) -> bool:
            _, short = col.split(":", 1)
            return col in features or short in features
        feature_columns = [c for c in feature_columns if _wanted(c)]

    gpu_meter_for_col = {key: meter for key, meter in gpu_cols}

    # ----- Build rows -----
    rows: list[dict] = []
    for slug in region_slugs:
        meters = region_meters[slug]
        has_consumption = any(
            m.startswith("Standard ") and "GPU" not in m for m in meters
        )
        has_dedicated = any(
            m.startswith("Dedicated ") and "GPU" not in m for m in meters
        )
        has_sessions = "Dynamic Sessions" in meters

        row: dict = {"region": slug}
        for col in feature_columns:
            kind, name = col.split(":", 1)
            if kind == "rt":
                if name == "sessionPools":
                    row[col] = has_sessions
                else:
                    # managedEnvironments / containerApps / jobs follow the
                    # presence of Container Apps in the region.
                    row[col] = True
            elif kind == "wp":
                if name == "Consumption":
                    row[col] = has_consumption
                elif name == "Dedicated":
                    row[col] = has_dedicated
                else:
                    # GPU column — driven by its specific billing meter.
                    row[col] = gpu_meter_for_col.get(col, "") in meters
            elif kind == "az":
                row[col] = slug in _AVAILABILITY_ZONE_REGIONS
        rows.append(row)

    return feature_columns, region_slugs, rows


# ---------------------------------------------------------------------------
# Report generation
# ---------------------------------------------------------------------------

def _generate_json_report(
    feature_columns: list[str],
    rows: list[dict],
    output_dir: Path,
    generated_at: datetime,
) -> Path:
    """Write a JSON report to *output_dir*/region-features.json."""
    json_path = output_dir / "region-features.json"

    features_list = []
    for col in feature_columns:
        _, name = col.split(":", 1)
        category, group = _categorize_feature(col)
        features_list.append({
            "key": col,
            "name": name,
            "display_name": _feature_display_name(col),
            "category": category,
            "group": group,
        })

    regions_list = []
    for row in rows:
        slug = row["region"]
        feature_values: dict[str, bool | None] = {}
        for col in feature_columns:
            val = row.get(col)
            feature_values[col] = None if val is None else bool(val)
        regions_list.append({
            "slug": slug,
            "display_name": _region_display_name(slug),
            "features": feature_values,
        })

    report = {
        "schema_version": 1,
        "generated_at": generated_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "data_source": "Azure Retail Prices API (https://prices.azure.com)",
        "note": (
            "Availability is derived from published billing meters. Consumption, "
            "Dedicated and Dynamic Sessions reflect where the meters are offered; "
            "specific dedicated profile sizes are not distinguished. GPU SKUs are "
            "differentiated. Availability Zone support comes from a maintained "
            "static list."
        ),
        "region_count": len(rows),
        "feature_count": len(feature_columns),
        "features": features_list,
        "regions": regions_list,
    }

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
        f.write("\n")

    return json_path


def _generate_csv_report(
    feature_columns: list[str],
    rows: list[dict],
    output_dir: Path,
    timestamp_str: str,
) -> Path:
    """Write a CSV report to *output_dir*."""
    csv_path = output_dir / f"aca_region_features_{timestamp_str}.csv"

    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["Region"] + feature_columns)
        for row in rows:
            writer.writerow(
                [row["region"]] + ["✓" if row.get(c) else "✗" for c in feature_columns]
            )

    return csv_path


def _generate_markdown_report(
    feature_columns: list[str],
    rows: list[dict],
    output_dir: Path,
    timestamp_str: str,
    generated_at: datetime,
) -> Path:
    """Write a Markdown report to *output_dir*."""
    md_path = output_dir / f"aca_region_features_{timestamp_str}.md"

    def _header(col: str) -> str:
        _, name = col.split(":", 1)
        return name

    headers = ["Region"] + [_header(c) for c in feature_columns]

    with open(md_path, "w", encoding="utf-8") as f:
        f.write("# Azure Container Apps — Region Feature Matrix\n\n")
        f.write(f"_Generated {generated_at.strftime('%Y-%m-%d %H:%M:%S UTC')}_\n\n")

        total_regions = len(rows)
        f.write(f"**{total_regions} region(s)**, **{len(feature_columns)}** features.\n\n")

        f.write("| " + " | ".join(headers) + " |\n")
        f.write("| " + " | ".join(["---"] * len(headers)) + " |\n")

        for row in rows:
            cells = [row["region"]] + [
                "✓" if row.get(c) else "✗" for c in feature_columns
            ]
            f.write("| " + " | ".join(cells) + " |\n")

    return md_path


def generate_reports(
    feature_columns: list[str],
    rows: list[dict],
    output_dir: Path,
    output_format: str = "all",
):
    """Write reports to *output_dir* based on *output_format*."""
    output_dir.mkdir(parents=True, exist_ok=True)
    now = datetime.now(timezone.utc)
    ts = now.strftime("%Y%m%d_%H%M%S")

    paths: list[tuple[str, Path]] = []

    if output_format in ("all", "json"):
        paths.append(("JSON", _generate_json_report(feature_columns, rows, output_dir, now)))
    if output_format in ("all", "csv"):
        paths.append(("CSV", _generate_csv_report(feature_columns, rows, output_dir, ts)))
    if output_format in ("all", "markdown"):
        paths.append(("Markdown", _generate_markdown_report(feature_columns, rows, output_dir, ts, now)))

    print("\nReports written:")
    for label, p in paths:
        print(f"  {label:10s} {p}")

    return tuple(p for _, p in paths)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description=(
            "Discover Azure Container Apps feature availability across regions "
            "using the public Azure Retail Prices API (no authentication)."
        )
    )
    parser.add_argument(
        "--subscription-id",
        default=None,
        help="Deprecated / ignored. Retained for backward compatibility; the "
             "script no longer authenticates to Azure.",
    )
    parser.add_argument(
        "--regions",
        nargs="*",
        default=None,
        help="Optional list of region slugs (e.g. eastus westeurope). "
             "If omitted, all regions are reported.",
    )
    parser.add_argument(
        "--features",
        nargs="*",
        default=None,
        help="Optional list of feature keys to report. Use prefixed form "
             "(rt:sessionPools, wp:Consumption, az:AvailabilityZones) or short "
             "names. If omitted, all features are reported.",
    )
    parser.add_argument(
        "--regions-only",
        action="store_true",
        help="Only list the available regions and exit.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("."),
        help="Directory to write reports to (default: current directory).",
    )
    parser.add_argument(
        "--output-format",
        choices=["all", "json", "csv", "markdown"],
        default="all",
        help="Report format to produce (default: all).",
    )
    # Accepted but ignored — kept so existing invocations do not break.
    parser.add_argument("--max-workers", type=int, default=10,
                        help="Deprecated / ignored.")
    parser.add_argument("--verify-session-pools", action="store_true",
                        help="Deprecated / ignored (sessionPools come from pricing meters).")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    if args.regions_only:
        items = fetch_aca_price_items()
        slugs = sorted(build_region_meters(items))
        print(f"Azure Container Apps is offered in {len(slugs)} region(s):\n")
        for s in slugs:
            print(f"  {s}")
        return

    feature_columns, _region_slugs, rows = discover(
        regions=args.regions,
        features=args.features,
    )

    generate_reports(feature_columns, rows, args.output_dir, args.output_format)


if __name__ == "__main__":
    main()
