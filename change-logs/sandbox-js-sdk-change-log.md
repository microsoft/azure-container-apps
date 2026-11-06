 # Azure Container Apps Sandbox javascript client library

## 1.0.0-beta.1 

### Breaking Changes

- Disk-image creation now uses `PUT /diskimages/v2`. The exported
  `CreateDiskImageRequest` uses a nested registry `source`, not `image.base`.
  Removed the ineffective disk-image `entrypoint` and `cmd` create options;
  configure command overrides when creating a sandbox instead. Response metadata
  and sandbox command options are unchanged.
- `managedIdentityResourceId` now selects registry authentication: use `system`
  or a user-assigned identity ARM resource ID. The latter is resolved through ARM
  and requires permission to read that identity. Registry credentials and identity
  are mutually exclusive; invalid credentials or failed lookups stop creation.

- Sandbox create, `ports.add`, and `ports.update` now default ports with no
  enabled authentication provider to anonymous access, matching the portal.
  This includes numeric update shorthand, missing/empty auth, disabled Entra
  auth, and `anonymous: false` without a nonempty email. These ports are
  accessible without authentication instead of returning HTTP 409.
  Enabled Entra ID policies are preserved; configure one to require auth.
  Anonymous fallback omits disabled providers so stored/echoed configurations
  remain readable by the Python SDK.

### Features Added

- Add typed TDS and PostgreSQL policy sections, credentials, rules, and decision hooks.

Initial preview of the Azure Container Apps Sandbox client library for
JavaScript, restructured to match the modular Azure SDK for JavaScript layout
(as used by `@azure/arm-appcontainers`):

- Dual ESM / CommonJS build via `tshy`, `type: "module"`, and subpath exports
  (`.`, `./api`, `./api/<operationGroup>`, `./models`).
- Built on `@azure-rest/core-client`, `@azure/core-lro`, and
  `@azure/core-rest-pipeline`.
- `src/api` (operation functions + context), `src/classic` (operation-group
  wrappers), `src/models` (interfaces + serializers), and `src/static-helpers`
  (paging + polling) layout.

#### Clients and operation groups

- **`ContainerAppsSandboxManagementClient`** (ARM control plane):
  - `sandboxGroups`: `get`, `list`, `beginCreateOrUpdate`, `beginDelete`,
    `beginUpdateIdentity`, `createOrUpdateVnetConnection`, `deleteVnetConnection`.
- **`SandboxGroupClient`** (data plane):
  - `sandboxes`: `get`, `list`, `beginCreate`, `delete`, `beginDelete`, `exec`,
    `getStats`, `setLifecyclePolicy`, `beginStop`, `beginResume`,
    `beginCreateSnapshot`, `beginCommit`, `addVolumeMount`.
  - `diskImages`: `list`, `listPublic`, `get`, `getPublic`, `beginCreate`,
    `delete`, `beginDelete`.
  - `snapshots`: `list`, `get`, `delete`, `beginDelete`.
  - `volumes`: `list`, `get`, `create`, `delete`, `beginDelete`.
  - `secrets`: `list`, `upsert`, `delete`, `listKeys`, `peek`.
  - `ports`: `add`, `remove`, `update`.
  - `egress`: `getPolicy`, `setPolicy`, `getDecisions`.
  - `files`: `list`, `stat`, `read`, `write`, `delete`, `mkdir`.

Long-running operations return a `PollerLike<OperationState<T>, T>`; list
operations return a `PagedAsyncIterableIterator`.