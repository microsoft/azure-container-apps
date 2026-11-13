# Publish a post

Add **one Markdown file** here. No template or navigation updates are needed.

1. [Create a post in GitHub](https://github.com/microsoft/azure-container-apps/new/main/_posts).
2. Name it `YYYY-MM-DD-your-post-title.md` and paste the template below.
3. Write the post and open a pull request. After approval and merge, GitHub
   Actions builds and publishes the site automatically.

```markdown
---
title: "Your post title"
tags: [scaling, tutorials]
---

A short opening paragraph that also appears in the post list.

<!--more-->

## Your first heading

The rest of your post goes here.
```

The filename supplies the publication date. Posts are listed newest first;
future-dated posts stay hidden until a build on or after that date. Dates use
UTC. New tags appear in the topic index automatically. Use a YAML list of
tags; you can also omit tags entirely.

`description: "A short summary"` is optional. When present it replaces the
opening paragraph in post lists and link previews. The `<!--more-->` marker
keeps the rest of the article out of the list preview.

Put images under `assets/images/` and use a base-path-aware link:

```liquid
![Describe the image]({{ '/assets/images/your-image.png' | relative_url }})
```

For links to other site pages, use `relative_url` in the same way so links
work under the repository's `/azure-container-apps` URL.
