# Azure Container Apps Sandbox javascript client library

## 1.0.0-beta.1 

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