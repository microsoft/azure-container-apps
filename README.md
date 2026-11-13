# Azure Container Apps

Azure Container Apps is a developer-first, serverless platform that allows you to maintain less infrastructure and save costs while running containerized applications. It scales from zero to hyperscale and instead of worrying about server configuration, container orchestration, and deployment details, Container Apps provides all the up-to-date server resources required to keep your applications stable and secure.

With Azure Container Apps, you can:

- **Run jobs** on-demand, on a schedule, or based on events
- **Autoscale** your apps based on any KEDA-supported scale trigger — most applications can scale to zero
- **Split traffic** across multiple versions of an application for Blue/Green deployments and A/B testing
- **Use internal ingress and service discovery** for secure internal-only endpoints with built-in DNS-based service discovery
- **Run applications on serverless or reserved CPU and GPU**


## Get Started

- **Blog**: [Azure Container Apps blog](https://microsoft.github.io/azure-container-apps/) · [Publish a post](_posts/README.md)
- **Latest Updates**: [Pinned monthly update in issues](https://github.com/microsoft/azure-container-apps/issues)
- **In-flight work**: [External Roadmap](https://github.com/orgs/microsoft/projects/540)
- **Samples & updates**: [aka.ms/aca/start](https://aka.ms/aca/start)
- **Documentation**: [aka.ms/containerapps/docs](https://aka.ms/containerapps/docs)
- **Product overview**: [aka.ms/containerapps](https://aka.ms/containerapps)




## Blog source and local preview

The blog's Jekyll source lives at the repository root: `_posts` for Markdown
posts, `_layouts` and `_includes` for templates, `assets` for styling, and
`_config.yml` for site settings. [Adding a post](_posts/README.md) only requires
one Markdown file; date, tag, and author navigation update automatically.

With Ruby and Bundler installed:

```sh
bundle install
bundle exec jekyll serve
```

Open `http://localhost:4000/azure-container-apps/`. The existing
`aca-getting-started/` resource hub is preserved. GitHub Actions validates
pull requests and builds the site with the official GitHub Pages Jekyll
action, then publishes `_site` after a merge to `main`.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.