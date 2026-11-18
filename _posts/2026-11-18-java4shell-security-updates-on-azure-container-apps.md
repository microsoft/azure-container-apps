---
title: "Java4Shell Security Updates on Azure Container Apps"
tags: [security, java]
---

If you run Java workloads on Azure Container Apps, review and patch them immediately. A critical vulnerability, **CVE-2026-114938** ("Java4Shell"), in the OpenJDK HotSpot JVM can corrupt memory, and potentially allow code execution, when an application decodes untrusted Base64 input. Common examples are authentication tokens, headers, cookies and request payloads.

<!--more-->

**Affected:** Unpatched OpenJDK 17.0.6 and later in the 17 release line, as well as OpenJDK 21, 25 and 27, on x86-64 CPUs that support AVX-512 VBMI. OpenJDK 8, Java 11 and ARM64 workloads are not affected. Oracle Java 8 Enterprise Performance Pack is an exception.

See the [official advisory](https://openjdk.org/groups/vulnerability/advisories/2026-11-17).

## What you need to do

### Patch Java

Update to **Microsoft Build of OpenJDK 17.0.21.1, 21.0.13.1 or 25.0.5.1**, matching your version, or a later supported release that includes the fix. If you use another JDK distribution, confirm the fixed version with your vendor. Oracle Java 8 Enterprise Performance Pack is an exception, with **8u513-perf** as its fixed release.

The first fixed release lines for [Microsoft Build of OpenJDK](https://learn.microsoft.com/en-us/java/openjdk/release-notes) are:

| Java release line | First fixed release |
| --- | --- |
| Java 17 | 17.0.21.1 |
| Java 21 | 21.0.13.1 |
| Java 25 | 25.0.5.1 |

### Rebuild your images

The existing `mcr.microsoft.com/openjdk/jdk` tags (for example `17-azurelinux`, `17-ubuntu`, `17-distroless`, and the 21 and 25 equivalents) were updated in place with patched images. Images you built earlier still contain the vulnerable JDK until you rebuild them. If your Dockerfile pins the base image by digest, update it to the new digest.

### Redeploy

Deploy patched images, verify that all active app revisions use patched images, then deactivate vulnerable revisions. Updating the image in your registry alone is not enough. For jobs, update the image and stop any executions still using an affected image. See the [deployment guidance](https://learn.microsoft.com/azure/container-apps/revisions) and [job execution guidance](https://learn.microsoft.com/azure/container-apps/jobs).

### Confirm the runtime version

Check your app's startup logs, or run `java -version` in the container console, to confirm it reports the patched release.

## Can't patch immediately?

As a temporary mitigation, add `-XX:-UseBASE64Intrinsics` to the `JAVA_TOOL_OPTIONS` environment variable of affected apps and jobs. Create a new app revision or update the job so that new executions pick up the setting. This disables the vulnerable code path, at a small cost to Base64 throughput.

If your apps are internet-facing, also consider requiring authentication (for example, [built-in authentication](https://learn.microsoft.com/azure/container-apps/authentication) with unauthenticated requests rejected), or restricting access, until you patch. Temporary measures do not replace the security update.

## Managed Java components

For managed Java components (Admin for Spring, Config Server for Spring, Eureka Server for Spring and Gateway for Spring), Microsoft is rolling out a platform update that applies this mitigation automatically. Each component restarts once during the update, and you don't need to do anything. Patched component images will follow. Your own Java apps that connect to these components still need the steps above.

Thank you, Microsoft Azure Container Apps Team
