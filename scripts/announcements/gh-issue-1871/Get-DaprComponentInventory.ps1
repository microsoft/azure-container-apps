[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [guid] $SubscriptionId,
    [string] $EnvironmentId,
    [string] $OutputDirectory = (Join-Path (Get-Location) (
        'dapr-scope-audit-{0}-{1}' -f $SubscriptionId.ToString(), (Get-Date -Format 'yyyyMMdd-HHmmssfff')
    )),
    [string] $ApiVersion = '2025-07-01'
)

$ErrorActionPreference = 'Stop'
$subscription = $SubscriptionId.ToString()
$cloudJson = & az cloud show --output json --only-show-errors
if ($LASTEXITCODE -ne 0) { throw 'Cannot read the active Azure cloud. Sign in with az login first.' }
$cloud = ($cloudJson -join "`n") | ConvertFrom-Json
$script:ArmBase = $cloud.endpoints.resourceManager.TrimEnd('/')
$script:ArmHost = ([uri] $script:ArmBase).Host
if ($EnvironmentId) {
    $pattern = '^/subscriptions/' + [regex]::Escape($subscription) +
        '/resourceGroups/[^/]+/providers/Microsoft\.App/managedEnvironments/[^/]+$'
    if ($EnvironmentId -notmatch $pattern) {
        throw 'EnvironmentId must be a managed environment ARM ID within SubscriptionId.'
    }
}

function Invoke-ArmGet {
    param([Parameter(Mandatory)][string] $Resource)
    $uri = if ($Resource.StartsWith('/')) { $script:ArmBase + $Resource } else { $Resource }
    $parsed = [uri] $uri
    if ($parsed.Scheme -ne 'https' -or $parsed.Host -ne $script:ArmHost) {
        throw 'Unexpected ARM pagination endpoint.'
    }
    try {
        return Invoke-RestMethod -Method Get -Uri $uri -Headers $script:ArmHeaders `
            -MaximumRedirection 0 -TimeoutSec 90
    } catch {
        throw "ARM GET failed for $Resource. Audit stopped; no complete report was produced. $($_.Exception.Message)"
    }
}

function Get-ArmCollection {
    param([Parameter(Mandatory)][string] $Resource)
    $next = $Resource
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    while ($next) {
        if (-not $seen.Add($next)) { throw 'ARM pagination returned a repeated page.' }
        $page = Invoke-ArmGet $next
        if ($null -eq $page.value) { throw 'ARM collection response has no value array.' }
        foreach ($item in $page.value) { $item }
        $next = $page.nextLink
    }
}

function Get-EffectiveDapr {
    param($App)
    $config = $App.properties.configuration.dapr
    if ($null -eq $config) { $config = $App.properties.template.dapr }
    $enabled = $false
    if ($null -ne $config.enabled) {
        if ($config.enabled -is [bool]) {
            $enabled = $config.enabled
        } elseif (-not [bool]::TryParse([string] $config.enabled, [ref] $enabled)) {
            throw "Unexpected Dapr enabled value for $($App.id)."
        }
    }
    $appId = [string] $config.appId
    if ([string]::IsNullOrEmpty($appId)) { $appId = $App.name }
    return [pscustomobject]@{ Enabled = $enabled; AppId = $appId }
}

$tokenJson = & az account get-access-token --subscription $subscription `
    --resource $cloud.endpoints.activeDirectoryResourceId --output json --only-show-errors
if ($LASTEXITCODE -ne 0) { throw 'Cannot acquire an ARM access token from the signed-in Azure CLI account.' }
$credential = ($tokenJson -join "`n") | ConvertFrom-Json
$script:ArmHeaders = @{ Authorization = 'Bearer ' + $credential.accessToken }
$credential = $null
$tokenJson = $null
try {
$started = [DateTime]::UtcNow
if ($EnvironmentId) {
    $environments = @(Invoke-ArmGet "${EnvironmentId}?api-version=$ApiVersion")
} else {
    $environments = @(Get-ArmCollection (
        "/subscriptions/$subscription/providers/Microsoft.App/managedEnvironments?api-version=$ApiVersion"))
}
# Subscription-wide app discovery includes apps in a different resource group from their environment.
$allApps = @(Get-ArmCollection (
    "/subscriptions/$subscription/providers/Microsoft.App/containerApps?api-version=$ApiVersion"))
$appsByEnvironment = @{}
$appInventory = [System.Collections.Generic.List[object]]::new()
foreach ($app in $allApps) {
    $appEnvironment = [string] $app.properties.environmentId
    if ([string]::IsNullOrEmpty($appEnvironment)) {
        $appEnvironment = [string] $app.properties.managedEnvironmentId
    }
    if ([string]::IsNullOrEmpty($appEnvironment)) { continue }
    $key = $appEnvironment.ToLowerInvariant()
    if (-not $appsByEnvironment.ContainsKey($key)) {
        $appsByEnvironment[$key] = [System.Collections.Generic.List[object]]::new()
    }
    $dapr = Get-EffectiveDapr $app
    $row = [pscustomobject]@{
        EnvironmentId = $appEnvironment
        AppResourceId = $app.id
        AppName = $app.name
        DaprEnabled = $dapr.Enabled
        DaprAppId = $dapr.AppId
    }
    $appsByEnvironment[$key].Add($row)
}

$componentInventory = [System.Collections.Generic.List[object]]::new()
$environmentInventory = [System.Collections.Generic.List[object]]::new()
$findings = [System.Collections.Generic.List[object]]::new()
foreach ($environment in $environments) {
    Write-Host "Checking $($environment.id)"
    $key = $environment.id.ToLowerInvariant()
    $apps = @()
    if ($appsByEnvironment.ContainsKey($key)) {
        $apps = @($appsByEnvironment[$key].ToArray())
    }
    foreach ($row in $apps) { $appInventory.Add($row) }
    $components = @(Get-ArmCollection (
        $environment.id + "/daprComponents?api-version=$ApiVersion"))
    $enabledIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $disabledIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($app in $apps) {
        if ($app.DaprEnabled) { [void] $enabledIds.Add($app.DaprAppId) }
        else { [void] $disabledIds.Add($app.DaprAppId) }
    }
    $environmentFindingsBefore = $findings.Count
    $scopedComponents = 0
    foreach ($component in $components) {
        $scopes = @($component.properties.scopes)
        if ($null -eq $component.properties.scopes) { $scopes = @() }
        $componentInventory.Add([pscustomobject]@{
            EnvironmentId = $environment.id
            ComponentResourceId = $component.id
            ComponentName = $component.name
            Scopes = ConvertTo-Json -InputObject $scopes -Compress
            ScopeCount = $scopes.Count
        })
        if ($scopes.Count -eq 0) {
            $findings.Add([pscustomobject]@{
                EnvironmentId = $environment.id; ComponentResourceId = $component.id
                ComponentName = $component.name; Scope = ''; Finding = 'EmptyScopes'
                Action = 'Review legacy all-app access; add explicit existing Dapr-enabled app IDs or remove this component'
            })
            continue
        }
        $scopedComponents++
        foreach ($scope in $scopes) {
            $text = [string] $scope
            if ([string]::IsNullOrWhiteSpace($text)) {
                $kind = 'InvalidScope'
                $action = 'Remove the invalid scope entry.'
            } elseif ($enabledIds.Contains($text) -or $disabledIds.Contains($text)) {
                # Existing Dapr-disabled matches are excluded from this remediation report.
                continue
            } else {
                $kind = 'NoMatchingDaprAppId'
                $action = 'Replace/remove the stale ID while keeping valid nonempty scopes, or create the intended Dapr-enabled app first. If unused, consider deleting the component explicitly.'
            }
            $findings.Add([pscustomobject]@{
                EnvironmentId = $environment.id; ComponentResourceId = $component.id
                ComponentName = $component.name; Scope = $text; Finding = $kind
                Action = $action
            })
        }
    }
    $environmentInventory.Add([pscustomobject]@{
        EnvironmentId = $environment.id
        EnvironmentName = $environment.name
        Location = $environment.location
        DaprEnabledApps = @($apps | Where-Object DaprEnabled).Count
        Components = $components.Count
        ScopedComponents = $scopedComponents
        Findings = $findings.Count - $environmentFindingsBefore
    })
}

# Reports are written only after every requested collection has been read successfully.
if (Test-Path -LiteralPath $OutputDirectory) {
    if (@(Get-ChildItem -LiteralPath $OutputDirectory -Force).Count) {
        throw 'OutputDirectory is not empty. Choose a new directory to avoid mixing audit runs.'
    }
} else {
    [void] (New-Item -ItemType Directory -Path $OutputDirectory)
}
foreach ($report in @(
    @{Name = 'environments.csv'; Data = $environmentInventory.ToArray()},
    @{Name = 'apps.csv'; Data = $appInventory.ToArray()},
    @{Name = 'components.csv'; Data = $componentInventory.ToArray()},
    @{Name = 'findings.csv'; Data = $findings.ToArray()}
)) {
    if ($report.Data.Count) {
        $report.Data | Export-Csv -LiteralPath (Join-Path $OutputDirectory $report.Name) -NoTypeInformation -Encoding UTF8
    }
}
$summary = [pscustomobject]@{
    Complete = $true
    SubscriptionId = $subscription
    StartedUtc = $started.ToString('o')
    CompletedUtc = [DateTime]::UtcNow.ToString('o')
    Environments = $environments.Count
    Components = $componentInventory.Count
    EmptyScopeComponents = @($findings | Where-Object Finding -eq 'EmptyScopes').Count
    MissingScopeReferences = @($findings | Where-Object Finding -eq 'NoMatchingDaprAppId').Count
    EnvironmentsWithMissingScopes = @($findings | Where-Object {
        $_.Finding -eq 'NoMatchingDaprAppId'
    } | Select-Object -ExpandProperty EnvironmentId -Unique).Count
}
$summary | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputDirectory 'summary.json') -Encoding UTF8
$summary | Format-List | Out-Host
} finally {
    $script:ArmHeaders.Clear()
    Remove-Variable ArmHeaders -Scope Script -ErrorAction SilentlyContinue
}
