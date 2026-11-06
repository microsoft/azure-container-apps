# Azure Container Apps Sandbox dotnet client library

## 1.0.0-beta.1

Initial preview release of the Azure Container Apps Sandbox client library for .NET.

### New Features

* Authenticate with Microsoft Entra ID using Azure Identity credentials.
* Connect to a sandbox group by Azure region or regional endpoint, with synchronous and asynchronous resource operations.
* Create, list, retrieve, and delete sandboxes, and manage lifecycle policies, stop/resume, and enable/disable operations.
* Configure sandbox networking, exposed ports, and volume mounts.
* Manage volumes, snapshots, secrets, connections, credentials, content packages, egress policies, and disk images, including public disk images.
* Read, write, upload, and download sandbox and volume files, and transfer content packages using streams.
* Execute commands, open interactive exec sessions and process streams over WebSocket, and stream logs over HTTP.