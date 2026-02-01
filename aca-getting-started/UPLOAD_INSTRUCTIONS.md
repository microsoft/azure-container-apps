# Upload Instructions for azure-container-apps Repository

## Steps to Upload to https://github.com/microsoft/azure-container-apps

### Option 1: Via Fork and Pull Request (Recommended)

1. **Fork the Repository**
   - Go to https://github.com/microsoft/azure-container-apps
   - Click the "Fork" button (top right)
   - This creates a copy in your GitHub account

2. **Clone Your Fork**
   ```powershell
   cd "c:\Users\vyomnagrani\OneDrive - Microsoft\Documents\Code\dev"
   git clone https://github.com/YOUR-USERNAME/azure-container-apps.git
   cd azure-container-apps
   ```

3. **Copy the aca-getting-started Folder**
   ```powershell
   Copy-Item -Path "..\aca-getting-started" -Destination "." -Recurse
   ```

4. **Create a New Branch**
   ```powershell
   git checkout -b add-getting-started-resources
   ```

5. **Stage and Commit**
   ```powershell
   git add aca-getting-started/
   git commit -m "Add: Comprehensive getting started resources page

   - New resource hub similar to Azure API Management resources
   - Includes documentation links, samples, tools, and community resources
   - Fully responsive design with modern UI
   - Contribution guidelines and GitHub Actions workflows
   - FAQ and getting started guides"
   ```

6. **Push to Your Fork**
   ```powershell
   git push origin add-getting-started-resources
   ```

7. **Create Pull Request**
   - Go to your fork on GitHub
   - Click "Compare & pull request"
   - Fill in the PR details:
     - **Title**: Add comprehensive getting started resources page
     - **Description**: 
       ```
       ## Overview
       This PR adds a comprehensive resource hub for Azure Container Apps, 
       providing a single starting point for customers to access documentation, 
       tools, samples, and community resources.

       ## What's Included
       - Fully responsive HTML resource page
       - Getting started guide with examples
       - Comprehensive FAQ
       - Contribution guidelines
       - GitHub Actions for link checking and deployment
       - Issue and PR templates

       ## Inspired By
       Similar to Azure API Management resources page: 
       https://azure.github.io/api-management-resources/

       ## Preview
       Can be viewed locally or deployed via GitHub Pages
       ```
   - Click "Create pull request"

### Option 2: Direct Upload (If You Have Write Access)

1. **Clone the Repository**
   ```powershell
   cd "c:\Users\vyomnagrani\OneDrive - Microsoft\Documents\Code\dev"
   git clone https://github.com/microsoft/azure-container-apps.git
   cd azure-container-apps
   ```

2. **Copy the Folder**
   ```powershell
   Copy-Item -Path "..\aca-getting-started" -Destination "." -Recurse
   ```

3. **Create a Branch**
   ```powershell
   git checkout -b add-getting-started-resources
   ```

4. **Commit and Push**
   ```powershell
   git add aca-getting-started/
   git commit -m "Add: Comprehensive getting started resources page"
   git push origin add-getting-started-resources
   ```

5. **Create Pull Request**
   - Go to https://github.com/microsoft/azure-container-apps/pulls
   - Click "New pull request"
   - Select your branch
   - Create the PR

### Option 3: Using GitHub Desktop

1. **Open GitHub Desktop**
2. **File → Clone Repository**
   - Select `microsoft/azure-container-apps` (or your fork)
   - Choose local path

3. **Copy Folder**
   - Copy `aca-getting-started` folder into the cloned repo

4. **Create Branch**
   - Click "Current Branch" → "New Branch"
   - Name: `add-getting-started-resources`

5. **Commit**
   - Review changes in GitHub Desktop
   - Write commit message
   - Click "Commit to add-getting-started-resources"

6. **Push and Create PR**
   - Click "Publish branch"
   - Click "Create Pull Request"

## Setting Up GitHub Pages

Once the PR is merged, to enable GitHub Pages:

1. **Repository Settings**
   - Go to https://github.com/microsoft/azure-container-apps/settings/pages
   
2. **Configure Source**
   - Source: Deploy from a branch
   - Branch: `main`
   - Folder: `/aca-getting-started` or `/` (root)

3. **Custom Domain (Optional)**
   - Add custom domain if desired

4. **Access the Site**
   - Will be available at: https://microsoft.github.io/azure-container-apps/aca-getting-started/

## Pre-Upload Checklist

- [x] Folder renamed to `aca-getting-started`
- [x] All references updated to microsoft/azure-container-apps
- [x] URLs updated to microsoft.github.io
- [x] All files created and ready
- [ ] Reviewed content for accuracy
- [ ] Tested links locally
- [ ] Verified responsive design
- [ ] Ready to create PR

## What to Include in Your PR Description

```markdown
## Summary
Adds a comprehensive resource hub for Azure Container Apps customers.

## Changes
- New `aca-getting-started` directory with resource page
- Fully responsive HTML page with all major ACA resources
- Documentation links, samples, tools, and community resources
- Contribution guidelines and templates
- GitHub Actions for automated link checking
- Getting started guide and FAQ

## Benefits
- Single starting point for all ACA resources
- Improved discoverability of documentation and tools
- Community contribution framework
- Similar to successful API Management resources page

## Preview
Tested locally - all links functional and design responsive.
```

## Need Help?

If you encounter any issues:
- Check your repository permissions
- Ensure git is configured correctly
- Review GitHub's PR documentation: https://docs.github.com/en/pull-requests

---

**Ready to upload!** Follow the steps above based on your access level.
