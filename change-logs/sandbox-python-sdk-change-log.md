
# Azure Container Apps Sandbox python client library

## 0.1.0b4

### Breaking Changes

- **Removed `SandboxState.Idle` from the type annotation**: The `"Idle"` value
  has been removed from the `Sandbox.state` Literal type. Sandboxes that were
  previously reported as `"Idle"` now appear as `"Stopped"` with
  `state_details.stopped_reason` set to `"Idle"`. This aligns with ADC service
  PR #6836.
- **Backward-compatible wire handling**: Legacy service responses that still
  return `state == "Idle"` continue to be accepted — `"Idle"` is kept as a
  resumable state in the client state machine and as a valid `begin_stop()`
  target to avoid breakage during mixed-rollout windows.

### Added

- **`SandboxStateDetails` model**: New dataclass exposed on `Sandbox.state_details`.
  Populated when a sandbox transitions to `"Stopped"`. Contains:
  - `stopped_reason` — why the sandbox stopped (`"Idle"`, `"Disabled"`, or
    `"UserStopped"`).
  - `stopped_at` — UTC wall-clock time of the transition (ISO-8601 string).
- **`SandboxStateDetails.is_auto_resume_allowed()`** — returns `False` when
  `stopped_reason` is `"Disabled"`, blocking auto-resume.
- **`StoppedReason` type alias** — `Literal["Idle", "Disabled", "UserStopped"]`,
  re-exported from the package root.

### Changed

- `SandboxClient.ensure_running()` (sync and async) now checks
  `state_details.stopped_reason` before attempting to resume. If the reason is
  `"Disabled"`, a `RuntimeError` is raised instead of calling resume.
- `begin_stop()` target states include `"Idle"` for backward compatibility with
  legacy service responses.

### Fixed

- Nullable array properties in API responses no longer cause model
  deserialization to iterate `None`. Contract-nullable arrays are normalized
  safely, while malformed non-array values now produce explicit errors.
  ([#396](https://github.com/coreai-microsoft/adc-devx/issues/396))

## 0.1.0b3

Version bump for the next Python SDK beta package.

## 0.1.0b2

### Added

- `disk_size` keyword on `create_sandbox` / `begin_create_sandbox` to set the
  base disk size (a storage quantity such as `"20Gi"`); maps to
  `resources.disk`.

### Fixed

- Allow `Disk`-mode auto-suspend (`auto_suspend_mode="Disk"`), which is required
  for sandboxes using DataDisk volumes.

## 0.1.0b1

First public beta. The shipped surface covers:

### Clients

- `SandboxGroupManagementClient` — ARM control-plane operations on
  `Microsoft.App/sandboxGroups` (create, get, list, delete, patch identity,
  with `begin_*` long-running counterparts driven by
  `azure.mgmt.core.polling.arm_polling.ARMPolling`).
- `SandboxGroupClient` — data-plane operations scoped to a sandbox group
  (sandbox CRUD, disk images, snapshots, volumes, secrets, pagination,
  label filtering).
- `SandboxClient` — sandbox-scoped data-plane operations (`exec`, files,
  ports, egress, lifecycle: `stop`, `resume`, `delete`, `commit`,
  `create_snapshot`).
- Async mirror under `azure.containerapps.sandbox.aio` for every client
  above.

### Long-running operations

- `begin_*` methods on every long-running operation return
  `azure.core.polling.LROPoller` (sync) or `AsyncLROPoller` (async). They
  support parallel launch, non-blocking poll, and `result(timeout=…)`.
- Polling primitives `ResourceStatePoller`, `ResourceExistsPoller`, and
  `DeletionPoller` (with async counterparts) implement
  `azure.core.polling.PollingMethod` for state-based polling against
  resource GET endpoints.

### Models

- Typed dataclass models in `azure.containerapps.sandbox._model_types/`
  for every payload (egress, lifecycle, ports, volumes, snapshots, images,
  secrets, stats, files, sandbox core, groups).
- PEP 561 `py.typed` marker.

### Authentication & endpoints

- `azure-identity` `TokenCredential` (sync) and `AsyncTokenCredential`
  (async).
- Regional endpoint via the `endpoint` parameter and the
  `endpoint_for_region()` helper.
- `api_version` parameter on all clients (default `2026-02-01-preview`).
- `RetryPolicy` covers 403 responses (~100 s budget) so RBAC propagation
  delays are absorbed transparently.

### Operations

- `list_*` operations return `ItemPaged` / `AsyncItemPaged` iterators that
  follow `nextLink` pagination.
- `list_sandboxes()` supports label-based filtering.
- Secrets use group-scoped paths (`list_secret_keys`, `peek_secret`).
- Egress: `set_egress_default`, `add_egress_host_rule`, `set_egress_policy`,
  and decision auditing via `list_egress_decisions`.
- Volumes: blob and disk volumes with mount specs.