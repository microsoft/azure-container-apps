# Contributing to Azure Container Apps Resources

Thank you for your interest in contributing to the Azure Container Apps Resources page! This page serves as a central hub for the Azure Container Apps community, and we welcome contributions that help make it better.

## 📋 Table of Contents
- [Ways to Contribute](#ways-to-contribute)
- [Getting Started](#getting-started)
- [Contribution Guidelines](#contribution-guidelines)
- [Pull Request Process](#pull-request-process)
- [Content Standards](#content-standards)
- [Code of Conduct](#code-of-conduct)

## 🤝 Ways to Contribute

You can contribute in several ways:

1. **Add New Resources**
   - Documentation links
   - Code samples and demos
   - Tools and extensions
   - Blog posts and articles
   - Video tutorials
   - Community projects

2. **Update Existing Content**
   - Fix broken links
   - Update outdated information
   - Improve descriptions
   - Enhance formatting

3. **Report Issues**
   - Broken links
   - Outdated content
   - Missing resources
   - Suggestions for improvement

4. **Improve Design**
   - Enhance accessibility
   - Improve responsive design
   - Optimize performance
   - Better user experience

## 🚀 Getting Started

### Prerequisites
- A GitHub account
- Basic knowledge of HTML/CSS (for content updates)
- Familiarity with Azure Container Apps (helpful but not required)

### Fork and Clone

1. Fork this repository by clicking the "Fork" button at the top right
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/azure-container-apps.git
   cd azure-container-apps/aca-getting-started
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/microsoft/azure-container-apps.git
   ```

### Local Development

1. Open `index.html` in your browser to preview changes
2. Make your edits in a text editor or IDE
3. Refresh the browser to see updates

## 📝 Contribution Guidelines

### Adding New Resources

When adding new resources, please:

1. **Choose the Right Section**
   - Getting Started - For beginner content
   - Documentation - For official docs and guides
   - Samples & Demos - For code examples
   - Tools - For development tools
   - Learning - For educational content
   - Community - For community resources
   - Updates - For new features and announcements

2. **Follow the Card Format**
   ```html
   <div class="card">
       <h4>Resource Title</h4>
       <p>Clear, concise description of the resource (1-2 sentences).</p>
       <a href="https://example.com" target="_blank">Action Text →</a>
   </div>
   ```

3. **Use Appropriate Tags**
   - `<span class="tag new">New</span>` - For recently added features
   - `<span class="tag preview">Preview</span>` - For preview/beta features

### Link Guidelines

- **Use Official Sources First**: Prefer links to learn.microsoft.com, github.com/microsoft, or other official Microsoft domains
- **Verify Links**: Ensure all links are working before submitting
- **Use HTTPS**: Always use HTTPS URLs when available
- **Target Blank**: External links should open in new tabs (`target="_blank"`)
- **Descriptive Text**: Link text should clearly describe the destination

### Content Quality

- **Clarity**: Descriptions should be clear and concise
- **Accuracy**: Information must be current and correct
- **Relevance**: Content must be directly related to Azure Container Apps
- **No Marketing**: Avoid promotional language; focus on value
- **Proper Grammar**: Use correct spelling and grammar

## 🔄 Pull Request Process

### Before Submitting

1. **Sync with Upstream**
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/add-new-resource
   ```

3. **Make Your Changes**
   - Edit `index.html` or other files
   - Test locally by opening in browser
   - Verify all links work

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "Add: New resource for XYZ"
   ```

### Commit Message Format

Use clear, descriptive commit messages:

```
Type: Brief description

Examples:
- Add: New sample for Dapr integration
- Update: Pricing section with latest information
- Fix: Broken link to documentation
- Improve: Accessibility for navigation menu
```

Types:
- `Add`: New content or features
- `Update`: Changes to existing content
- `Fix`: Bug fixes or corrections
- `Remove`: Removed content
- `Improve`: Enhancements without changing functionality

### Submitting the PR

1. **Push to Your Fork**
   ```bash
   git push origin feature/add-new-resource
   ```

2. **Create Pull Request**
   - Go to your fork on GitHub
   - Click "New Pull Request"
   - Select your feature branch
   - Fill out the PR template

3. **PR Description Should Include**
   - What changes were made
   - Why the changes are needed
   - Link to any related issues
   - Screenshots (if visual changes)

### Review Process

1. A maintainer will review your PR
2. They may request changes or ask questions
3. Address feedback and push updates
4. Once approved, your PR will be merged

## ✅ Content Standards

### Required for New Resources

- [ ] Title is clear and descriptive
- [ ] Description is concise (1-2 sentences)
- [ ] Link is valid and works
- [ ] Link uses HTTPS
- [ ] Link opens in new tab (`target="_blank"`)
- [ ] Content is placed in the correct section
- [ ] Follows existing formatting
- [ ] No spelling or grammar errors

### Quality Checklist

- [ ] Information is accurate and current
- [ ] Resource is relevant to Azure Container Apps
- [ ] No duplicate content
- [ ] Consistent with existing style
- [ ] Works on mobile devices
- [ ] Accessible (proper HTML semantics)

## 🎨 Style Guide

### HTML/CSS

- Use semantic HTML5 elements
- Maintain existing indentation (2 spaces)
- Keep CSS organized by section
- Use CSS variables for colors
- Ensure responsive design

### Writing Style

- Use active voice
- Be concise and direct
- Avoid jargon when possible
- Use proper technical terms
- Follow Microsoft Writing Style Guide

### Formatting

- **Bold** for emphasis: `<strong>text</strong>`
- *Italics* for terms: `<em>text</em>`
- Links: `<a href="url" target="_blank">text</a>`
- Lists: Use `<ul>` and `<li>` for unordered lists

## 🐛 Reporting Issues

When reporting issues, please include:

1. **Issue Type**
   - Broken link
   - Outdated content
   - Missing resource
   - Bug or error
   - Suggestion

2. **Description**
   - Clear explanation of the issue
   - Steps to reproduce (if applicable)
   - Expected vs actual behavior

3. **Context**
   - Browser and version
   - Device type (desktop/mobile)
   - Screenshots (if helpful)

Use issue templates when available.

## 📋 Resource Submission Template

When suggesting a new resource via issue:

```markdown
## Resource Information

**Title**: [Resource name]
**URL**: [Link to resource]
**Section**: [Where it should be added]
**Description**: [Brief description]

## Why This Resource?

[Explain why this resource would be valuable to the community]

## Additional Context

[Any other relevant information]
```

## 🏆 Recognition

Contributors will be recognized in the following ways:

- GitHub contributor badge
- Name in CONTRIBUTORS.md (coming soon)
- Special thanks in release notes for significant contributions

## 📞 Getting Help

If you need help with contributing:

- **Questions**: [GitHub Discussions](https://github.com/microsoft/azure-container-apps/discussions)
- **Issues**: [GitHub Issues](https://github.com/microsoft/azure-container-apps/issues)
- **Contact**: Mention `@azure-container-apps-team` in issues or discussions

## 📜 Code of Conduct

This project follows the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of:
- Age, body size, disability, ethnicity
- Gender identity and expression
- Level of experience
- Nationality, personal appearance
- Race, religion, sexual identity and orientation

### Expected Behavior

- Use welcoming and inclusive language
- Be respectful of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Azure Container Apps Resources! Your efforts help make the Azure Container Apps community stronger and more accessible to everyone.

**Questions?** Open a [discussion](https://github.com/microsoft/azure-container-apps/discussions/new) - we're here to help! 🚀
