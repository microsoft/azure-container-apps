#!/usr/bin/env python3
"""Azure Container Apps Region Features Discovery Script.

Discovers which ACA features are available in which Azure regions by querying
the Azure ARM API and generates a report in markdown and CSV format.
"""

import argparse
import csv
import json
import re
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests as _requests
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

API_VERSION = "2024-03-01"

# Resource types under Microsoft.App whose per-region availability we check
RESOURCE_TYPES = [
    "managedEnvironments",
    "containerApps",
    "jobs",
    "sessionPools",
]

# Well-known workload-profile name prefixes we look for
WORKLOAD_PROFILE_PREFIXES = [
    "Consumption",
    "D4", "D8", "D16", "D32",
    "E4", "E8", "E16", "E32",
]
GPU_PROFILE_PREFIX = "Consumption-GPU"  # covers GPU workload profiles

# Well-known Azure region slug → display name mapping
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

# Pattern to split a region slug into words for best-effort display name
_REGION_WORD_PATTERN = re.compile(
    r"(north|south|east|west|central|southeast|northwest|northeast|southwest|"
    r"us|uk|uae|jio|dod|gov|euap|india|china|korea|japan|australia|brazil|"
    r"canada|france|germany|norway|sweden|switzerland|poland|italy|spain|"
    r"qatar|israel|saudi|arabia|africa|europe|asia|zealand|mexico|indonesia|"
    r"malaysia|taiwan|austria|belgium|denmark|finland|greece|\d+)",
    re.IGNORECASE,
)


# ---------------------------------------------------------------------------
# Helpers – display names
# ---------------------------------------------------------------------------

def _region_display_name(slug: str) -> str:
    """Convert a region slug to a human-readable display name."""
    if slug in _REGION_DISPLAY_NAMES:
        return _REGION_DISPLAY_NAMES[slug]

    # Best-effort: split on known word boundaries
    words = _REGION_WORD_PATTERN.findall(slug)
    if words:
        return " ".join(w.capitalize() if not w.isupper() else w for w in words)
    # Absolute fallback
    return slug.title()


def _camel_to_display(name: str) -> str:
    """Insert spaces before uppercase letters in camelCase/PascalCase names.

    'managedEnvironments' → 'Managed Environments'
    'containerApps'       → 'Container Apps'
    'AvailabilityZones'   → 'Availability Zones'
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
    # Workload profiles: keep name as-is
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
        if name == "Consumption":
            return "workload_profile", "Workload Profiles"
        if name.startswith("Consumption-GPU") or name.startswith("NC"):
            return "gpu", "GPU Profiles"
        # D*, E*, F*, DC*, EC*, Flex — dedicated profiles
        return "workload_profile", "Dedicated Profiles"
    return "other", "Other"


# ---------------------------------------------------------------------------
# Helpers – ARM
# ---------------------------------------------------------------------------

def _arm_get(credential, subscription_id: str, url_path: str, api_version: str):
    """Perform a raw ARM GET request and return the parsed JSON."""
    base_url = "https://management.azure.com"
    full_url = f"{base_url}{url_path}"
    sep = "&" if "?" in full_url else "?"
    full_url += f"{sep}api-version={api_version}"

    token = credential.get_token("https://management.azure.com/.default")
    headers = {"Authorization": f"Bearer {token.token}"}
    resp = _requests.get(full_url, headers=headers)
    resp.raise_for_status()
    return resp.json()


def get_provider_info(credential, subscription_id: str):
    """Return the Microsoft.App provider metadata (resource types + locations)."""
    client = ResourceManagementClient(credential, subscription_id)
    provider = client.providers.get("Microsoft.App")
    return provider


def get_all_aca_regions(provider) -> list[str]:
    """Extract the union of all locations advertised by Microsoft.App resource types."""
    regions: set[str] = set()
    for rt in provider.resource_types:
        if rt.locations:
            for loc in rt.locations:
                regions.add(loc)
    return sorted(regions)


def resource_type_locations(provider) -> dict[str, set[str]]:
    """Return a mapping of resource_type -> set of normalised region names."""
    mapping: dict[str, set[str]] = {}
    for rt in provider.resource_types:
        if rt.resource_type in RESOURCE_TYPES:
            mapping[rt.resource_type] = {_normalise(loc) for loc in (rt.locations or [])}
    return mapping


def _normalise(region_display_name: str) -> str:
    """Normalise an Azure region display name to a lowercase slug.

    e.g. 'East US' -> 'eastus', 'North Europe' -> 'northeurope'
    """
    return region_display_name.replace(" ", "").lower()


def get_workload_profiles_for_region(
    credential, subscription_id: str, location_slug: str
) -> list[str]:
    """Return the list of workload-profile *names* available in a region.

    Raises on API errors so callers can distinguish failures from empty results.
    """
    url = (
        f"/subscriptions/{subscription_id}/providers/Microsoft.App"
        f"/locations/{location_slug}/availableManagedEnvironmentsWorkloadProfileTypes"
    )
    data = _arm_get(credential, subscription_id, url, API_VERSION)

    names: list[str] = []
    for item in data.get("value", []):
        name = item.get("name") or item.get("properties", {}).get("displayName", "")
        if name:
            names.append(name)
    return names


def get_az_regions(credential, subscription_id: str) -> set[str]:
    """Return the set of region slugs that support Availability Zones."""
    url = f"/subscriptions/{subscription_id}/locations"
    data = _arm_get(credential, subscription_id, url, "2022-12-01")
    az_regions: set[str] = set()
    for loc in data.get("value", []):
        # availabilityZoneMappings is populated when the region has AZs
        mappings = loc.get("availabilityZoneMappings")
        if mappings:
            az_regions.add(loc.get("name", ""))
    return az_regions


TEMP_RG_NAME = "rg-aca-discovery-temp"
TEMP_RG_LOCATION = "eastus"


def _ensure_temp_rg(credential, subscription_id: str) -> str:
    """Create a temporary resource group for preflight validation and return its name."""
    client = ResourceManagementClient(credential, subscription_id)
    client.resource_groups.create_or_update(
        TEMP_RG_NAME, {"location": TEMP_RG_LOCATION}
    )
    return TEMP_RG_NAME


def _delete_temp_rg(credential, subscription_id: str):
    """Delete the temporary resource group."""
    client = ResourceManagementClient(credential, subscription_id)
    try:
        poller = client.resource_groups.begin_delete(TEMP_RG_NAME)
        print(f"  Deleting temp resource group '{TEMP_RG_NAME}' (async) ...")
    except Exception as e:
        print(f"  Warning: could not delete temp RG '{TEMP_RG_NAME}': {e}")


def validate_session_pools_in_region(
    credential, subscription_id: str, rg_name: str, location_slug: str
) -> bool:
    """Create and immediately delete a sessionPool to confirm deployability in a region.

    Returns True if the region supports sessionPools, False otherwise.
    """
    api = "2025-01-01"
    name = f"disc-sp-{uuid.uuid4().hex[:8]}"
    url = (
        f"https://management.azure.com/subscriptions/{subscription_id}"
        f"/resourceGroups/{rg_name}/providers/Microsoft.App/sessionPools/{name}"
        f"?api-version={api}"
    )
    body = {
        "location": location_slug,
        "properties": {
            "poolManagementType": "Dynamic",
            "containerType": "PythonLTS",
            "scaleConfiguration": {"maxConcurrentSessions": 5, "readySessionInstances": 0},
            "dynamicPoolConfiguration": {
                "executionType": "Timed",
                "lifecycleConfiguration": {"cooldownPeriodInSeconds": 300},
            },
        },
    }
    token = credential.get_token("https://management.azure.com/.default")
    headers = {"Authorization": f"Bearer {token.token}", "Content-Type": "application/json"}

    try:
        resp = _requests.put(url, headers=headers, json=body, timeout=60)
    except Exception:
        return False

    if resp.status_code in (200, 201, 202):
        # Successfully created — clean up
        try:
            _requests.delete(url, headers=headers, timeout=30)
        except Exception:
            pass
        return True

    # Check if the error is location-related
    try:
        data = resp.json()
    except Exception:
        return False

    error = data.get("error", {})
    error_code = error.get("code", "")
    error_msg = error.get("message", "").lower()

    # Location-specific rejections
    if error_code in ("LocationNotAvailableForResourceType", "InvalidResourceLocation"):
        return False
    if "not available in location" in error_msg or "not supported in this region" in error_msg:
        return False

    # Config/property errors mean the resource type IS available
    return True


# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

def discover(
    credential,
    subscription_id: str,
    regions: list[str] | None = None,
    features: list[str] | None = None,
    max_workers: int = 10,
    verify_session_pools: bool = False,
) -> tuple[list[str], list[str], list[dict]]:
    """Run the full discovery and return (feature_columns, region_slugs, rows).

    Each row is a dict: {"region": slug, feature1: bool|None, ...}
    Values are True (supported), False (not supported), or None (discovery failed).
    """

    print("Fetching Microsoft.App provider info ...")
    provider = get_provider_info(credential, subscription_id)
    rt_locs = resource_type_locations(provider)

    # Determine the set of regions to scan
    all_regions_display = get_all_aca_regions(provider)
    all_region_slugs = sorted({_normalise(r) for r in all_regions_display})

    if regions:
        # Filter to the user-specified list (accept both slugs and display names)
        normalised_input = {_normalise(r) for r in regions}
        region_slugs = sorted(s for s in all_region_slugs if s in normalised_input)
        if not region_slugs:
            print(f"  Warning: none of the requested regions matched. Available: {all_region_slugs[:10]} ...")
            sys.exit(1)
    else:
        region_slugs = all_region_slugs

    # Build the feature column list
    feature_columns: list[str] = []

    # 1) Resource types
    for rt in RESOURCE_TYPES:
        col = f"rt:{rt}"
        if features is None or col in features or rt in (features or []):
            feature_columns.append(col)

    # 2) Workload profiles -- discover the superset across all regions
    print(f"Querying workload profiles across {len(region_slugs)} region(s) ...")
    region_profiles: dict[str, list[str]] = {}
    wp_error_regions: set[str] = set()  # regions where profile discovery failed

    def _fetch_profiles(slug):
        return slug, get_workload_profiles_for_region(credential, subscription_id, slug)

    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        futures = {pool.submit(_fetch_profiles, s): s for s in region_slugs}
        for fut in as_completed(futures):
            try:
                slug, profiles = fut.result()
                region_profiles[slug] = profiles
            except Exception:
                slug = futures[fut]
                region_profiles[slug] = []
                wp_error_regions.add(slug)

    # Collect the superset of profile names
    all_profile_names: set[str] = set()
    for names in region_profiles.values():
        all_profile_names.update(names)

    # Order: well-known first, then GPU, then anything else
    ordered_profiles: list[str] = []
    for prefix in WORKLOAD_PROFILE_PREFIXES:
        if prefix in all_profile_names:
            ordered_profiles.append(prefix)
    # GPU / NC profiles
    for name in sorted(all_profile_names):
        if name.startswith(GPU_PROFILE_PREFIX) and name not in ordered_profiles:
            ordered_profiles.append(name)
    # Anything else we haven't seen
    for name in sorted(all_profile_names):
        if name not in ordered_profiles:
            ordered_profiles.append(name)

    for pname in ordered_profiles:
        col = f"wp:{pname}"
        if features is None or col in features or pname in (features or []):
            feature_columns.append(col)

    # 3) Availability Zones
    az_col = "az:AvailabilityZones"
    if features is None or az_col in features or "AvailabilityZones" in (features or []):
        feature_columns.append(az_col)

    print("Checking Availability Zone support ...")
    az_regions = get_az_regions(credential, subscription_id)

    # 4) Verify sessionPools via create+delete if requested
    check_session_pools = any(c == "rt:sessionPools" for c in feature_columns)
    session_pool_regions: set[str] = set()
    rg_name: str | None = None
    if check_session_pools and verify_session_pools:
        print("Verifying sessionPools via create+delete (per region) ...")
        rg_name = _ensure_temp_rg(credential, subscription_id)

        def _validate_sp(slug):
            return slug, validate_session_pools_in_region(
                credential, subscription_id, rg_name, slug
            )

        with ThreadPoolExecutor(max_workers=max_workers) as pool:
            futures = {pool.submit(_validate_sp, s): s for s in region_slugs}
            for fut in as_completed(futures):
                slug, available = fut.result()
                if available:
                    session_pool_regions.add(slug)

    # Build rows (tri-state: True / False / None)
    rows: list[dict] = []
    for slug in region_slugs:
        row: dict = {"region": slug}
        for col in feature_columns:
            kind, name = col.split(":", 1)
            if kind == "rt":
                if name == "sessionPools" and check_session_pools and verify_session_pools:
                    row[col] = slug in session_pool_regions
                else:
                    row[col] = slug in rt_locs.get(name, set())
            elif kind == "wp":
                if slug in wp_error_regions:
                    row[col] = None  # discovery failed for this region
                else:
                    row[col] = name in region_profiles.get(slug, [])
            elif kind == "az":
                row[col] = slug in az_regions
        rows.append(row)

    # Clean up temp RG
    if rg_name:
        _delete_temp_rg(credential, subscription_id)

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
        kind, name = col.split(":", 1)
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
            # Ensure tri-state: True, False, or None
            if val is None:
                feature_values[col] = None
            else:
                feature_values[col] = bool(val)
        regions_list.append({
            "slug": slug,
            "display_name": _region_display_name(slug),
            "features": feature_values,
        })

    report = {
        "schema_version": 1,
        "generated_at": generated_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
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

    # Pretty-print column headers (strip the kind prefix)
    def _header(col: str) -> str:
        _, name = col.split(":", 1)
        return name

    headers = ["Region"] + [_header(c) for c in feature_columns]

    with open(md_path, "w", encoding="utf-8") as f:
        f.write("# Azure Container Apps — Region Feature Matrix\n\n")
        f.write(f"_Generated {generated_at.strftime('%Y-%m-%d %H:%M:%S UTC')}_\n\n")

        # Summary
        total_regions = len(rows)
        f.write(f"**{total_regions} region(s)** scanned, **{len(feature_columns)}** features checked.\n\n")

        # Table header
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
    """Write reports to *output_dir* based on *output_format*.

    Supported formats: 'all' (default), 'json', 'csv', 'markdown'.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    now = datetime.now(timezone.utc)
    ts = now.strftime("%Y%m%d_%H%M%S")

    paths: list[tuple[str, Path]] = []

    if output_format in ("all", "json"):
        json_path = _generate_json_report(feature_columns, rows, output_dir, now)
        paths.append(("JSON", json_path))

    if output_format in ("all", "csv"):
        csv_path = _generate_csv_report(feature_columns, rows, output_dir, ts)
        paths.append(("CSV", csv_path))

    if output_format in ("all", "markdown"):
        md_path = _generate_markdown_report(feature_columns, rows, output_dir, ts, now)
        paths.append(("Markdown", md_path))

    print(f"\nReports written:")
    for label, p in paths:
        print(f"  {label:10s} {p}")

    return tuple(p for _, p in paths)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Discover Azure Container Apps feature availability across regions."
    )
    parser.add_argument(
        "--subscription-id",
        required=True,
        help="Azure subscription ID to query against.",
    )
    parser.add_argument(
        "--regions",
        nargs="*",
        default=None,
        help="Optional list of region slugs (e.g. eastus westeurope). If omitted, all regions are scanned.",
    )
    parser.add_argument(
        "--features",
        nargs="*",
        default=None,
        help=(
            "Optional list of feature keys to check. "
            "Use prefixed form (rt:jobs, wp:Dedicated-D4, az:AvailabilityZones) "
            "or short names (jobs, Dedicated-D4, AvailabilityZones). "
            "If omitted, all features are checked."
        ),
    )
    parser.add_argument(
        "--regions-only",
        action="store_true",
        help="Only list the available regions and exit (no feature discovery).",
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
    parser.add_argument(
        "--max-workers",
        type=int,
        default=10,
        help="Max concurrent API requests (default: 10).",
    )
    parser.add_argument(
        "--verify-session-pools",
        action="store_true",
        help="Verify sessionPools by actually creating and deleting a pool in each region (slower but definitive).",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    credential = DefaultAzureCredential()

    if args.regions_only:
        provider = get_provider_info(credential, args.subscription_id)
        all_regions = get_all_aca_regions(provider)
        slugs = sorted({_normalise(r) for r in all_regions})
        print(f"Azure Container Apps is available in {len(slugs)} region(s):\n")
        for s in slugs:
            print(f"  {s}")
        return

    feature_columns, region_slugs, rows = discover(
        credential,
        args.subscription_id,
        regions=args.regions,
        features=args.features,
        max_workers=args.max_workers,
        verify_session_pools=args.verify_session_pools,
    )

    generate_reports(feature_columns, rows, args.output_dir, args.output_format)


if __name__ == "__main__":
    main()
