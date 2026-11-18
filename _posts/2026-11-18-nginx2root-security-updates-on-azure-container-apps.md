---
title: "nginx2root Security Updates on Azure Container Apps"
tags: [security, nginx]
---

If you run nginx inside your Azure Container Apps applications or jobs, review and patch it immediately. A set of critical vulnerabilities in nginx, collectively called **"nginx2root"** (**CVE-2026-123007, CVE-2026-123633, CVE-2026-123634, CVE-2026-121810 and CVE-2026-113425**), can let an unauthenticated attacker run commands in your container with the privileges of the nginx worker process. The most widespread one, CVE-2026-123007, only requires HTTP/2 to be enabled.

<!--more-->

**Affected:** nginx 1.9.5 through 1.31.8 with HTTP/2 enabled, and other nginx releases in specific configurations (HTTP/3, request-time DNS resolution with `mirror` or other subrequests, or the mail proxy with `auth_http`). This includes images built on the official `nginx` image, distribution packages (for example Ubuntu, Debian), and frontend or reverse-proxy images that bundle nginx. See the [researchers' advisory](https://xint.io/blog/nginx2root-remote-code-execution).

**Not affected:** Container Apps ingress is built on Envoy, not nginx, so the platform's built-in ingress is not affected. Your own containers that run nginx are. If your app uses nginx with Container Apps TCP ingress, you are at highest risk.

## What you need to do

### Check whether your app is affected

Open the [console](https://learn.microsoft.com/azure/container-apps/container-console) for a running replica and run:

```bash
nginx -v                                                    # version
nginx -V 2>&1 | grep -o -- '--with-http_v2_module'          # HTTP/2 module present?
nginx -T 2>/dev/null | sed 's/#.*//' | grep -nE 'listen .*(http2|quic)|http2 +on|http3 +on|mirror|resolver|auth_http'
```

If the version is in the affected range and the last command finds `http2`, treat the app as affected. Distribution packages can carry a backported fix without changing the version that `nginx -v` prints, so check the full package version against your distribution's security advisory.

How your ingress is configured changes how directly nginx is exposed:

| Ingress setting | What reaches your nginx |
| --- | --- |
| `transport: tcp` | The client's raw connection. If nginx negotiates HTTP/2, it is **directly exposed** and at highest risk. |
| `transport: http2` (including gRPC apps) | HTTP/2 from the Container Apps ingress Envoy proxy. |
| `transport: auto` or `http` | HTTP/1.1 from the Container Apps ingress Envoy proxy. |

Patch in every case. Ingress settings do not replace the update.

### Patch nginx

Update to nginx mainline **1.31.9** or later (or **1.30.7** stable or later), or to your distribution's patched nginx package once it is available. If you use a distribution package, confirm with your vendor that the fix is included.

### Rebuild your images

Images you built earlier still contain the vulnerable nginx until you rebuild them. If your Dockerfile pins the base image by digest, update it to a patched digest.

### Redeploy

Deploy patched images, verify that all active app revisions use patched images, then deactivate vulnerable revisions. Updating the image in your registry alone is not enough. For jobs, update the image and stop any executions still using an affected image. See the [deployment guidance](https://learn.microsoft.com/azure/container-apps/revisions-manage) and [job execution guidance](https://learn.microsoft.com/azure/container-apps/jobs).

### Confirm the runtime version

Run `nginx -v` in the container console, or check your app's startup logs, to confirm it reports the patched release.

## Can't patch immediately?

As a temporary mitigation, change your nginx configuration, rebuild the image and deploy it as a new revision. Apply the item that matches your configuration:

- **HTTP/2 enabled (CVE-2026-123007, CVE-2026-123633):** disable HTTP/2. On nginx 1.25.1 and later, set `http2 off;` in every affected `server` block and remove `http2` from `listen` directives. On earlier versions, remove `http2` from `listen` directives (for example, `listen 443 ssl http2;` becomes `listen 443 ssl;`). Check every `server` block that shares the same listening port.
  - If your app uses ingress `transport: http2` only because nginx expects HTTP/2, change the ingress transport to `http` in the same update so the ingress talks HTTP/1.1 to nginx.
  - Clients that need HTTP/2 end to end, such as native gRPC, are affected by this change.
- **HTTP/3 / QUIC (CVE-2026-121810):** remove `listen ... quic` directives, set `http3 off;`, and replace any `Alt-Svc` header that advertises HTTP/3 with `add_header Alt-Svc 'clear' always;`.
- **`proxy_pass` with a variable, `resolver`, and `mirror` or other subrequests such as SSI (CVE-2026-123634):** point `proxy_pass` at a fixed `upstream` group instead of a name resolved at request time, and turn off `mirror` where you don't need it.
- **Mail proxy with `auth_http` (CVE-2026-113425):** don't expose the mail proxy to untrusted clients. Bind the IMAP/POP3/SMTP listeners to `127.0.0.1` if only processes in the same container need them.

Deploying the change as a new revision and deactivating the old one replaces the running nginx processes. Simply reloading nginx inside a running container is not enough, because existing HTTP/2 connections keep using the old workers.

If your apps are internet-facing, also consider restricting access until you patch. For HTTP ingress, use [IP restrictions](https://learn.microsoft.com/azure/container-apps/ip-restrictions) or [built-in authentication](https://learn.microsoft.com/azure/container-apps/authentication) with unauthenticated requests rejected. For TCP ingress, use [internal-only ingress](https://learn.microsoft.com/azure/container-apps/ingress-overview) or a [network security group](https://learn.microsoft.com/azure/container-apps/firewall-integration) on your environment's virtual network. Temporary measures do not replace the security update.

Thank you, Microsoft Azure Container Apps Team
