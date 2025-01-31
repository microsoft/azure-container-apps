# Container Apps Free Managed Certificates

IMPORTANT: When creating a free Managed Certificate, it is required that you prove ownership of the domain you are planning to use. Make sure [these steps](https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-managed-certificates?pivots=azure-portal#add-a-custom-domain-and-managed-certificate) are performed before running the template.

These bicep templates create the folowwing resources:

First template:
- a Container Apps Managed Environment using the Consumtpion + Dedicated Plan. This Managed Environment has only a Consumption Workload Profile.
- a Container App bound to a custom domain. This binding, is 'Disabled' since there is no certificate to secure it.
- a free Managed Certificate for the custom domain used in the Container App. If the domain ownership can be verified, the Managed Certificate will be succesfully created.

Second template:

- Changes the Container App to 'SniEnabled' now that the free Managed Cert has been succesfully created.

FUTURE IMPROVEMENT: We are working on removing the need for creating a Container App with a 'Disabled' binding before creating the free Managed Certificate.


[Learn More about Free Managed Certificates in Container Apps ](https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-managed-certificates?pivots=azure-portal)