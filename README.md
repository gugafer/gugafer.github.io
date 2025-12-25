# Gustavo's Tech Blog (gugafer.github.io)

![Status](https://img.shields.io/github/deployments/gugafer/gugafer.github.io/github-pages?label=GitHub%20Pages)
![Hugo](https://img.shields.io/badge/Hugo-v0.152.0+-blueviolet)
![Theme](https://img.shields.io/badge/Theme-PaperMod-green)

This is the source code for my personal engineering blog, focusing on **Cloud Architecture, DevSecOps, and Security** in enterprise environments.

## 🚀 Tech Stack

- **Static Site Generator:** [Hugo](https://gohugo.io/) (Extended Version)
- **Theme:** [PaperMod](https://github.com/adityatelange/hugo-PaperMod)
- **Hosting:** GitHub Pages
- **CI/CD:** GitHub Actions (Automated build & deploy)

## 📂 Project Structure

```
.
├── .github/workflows/  # CI/CD Pipeline configuration
├── archetypes/         # Templates for new posts
├── content/            # Markdown content (Posts & Pages)
├── layouts/            # HTML overrides for the theme
├── static/             # Images and static assets (favicon, etc.)
├── themes/             # Submodules (PaperMod)
├── config.yaml         # Main site configuration
└── CONTENT_INVENTORY.md # List of all published articles
```

## 🛠️ How to Run Locally

Prerequisites:
- [Hugo Extended](https://gohugo.io/installation/) installed.
- Git installed.

1. **Clone the repository:**
   ```bash
   git clone --recursive git@github.com:gugafer/gugafer.github.io.git
   cd gugafer.github.io
   ```

2. **Start the local server:**
   ```bash
   hugo server -D
   ```
   *The `-D` flag includes draft posts.*

3. **Access the site:**
   Open `http://localhost:1313` in your browser.

## 📝 Creating New Content

To create a new article with the correct front-matter:

```bash
hugo new posts/my-new-article-slug.md
```

This will create a file in `content/posts/` based on the template in `archetypes/posts.md`.

## ⚙️ Deployment & CI/CD

The deployment is fully automated via **GitHub Actions**.

- **Workflow File:** `.github/workflows/deploy.yml`
- **Trigger:** Pushing to the `main` branch.
- **Mechanism:**
    1. The pipeline installs Hugo (Latest Extended).
    2. It auto-fixes GitHub Pages settings (ensures "Workflow" source is selected).
    3. Builds the site using `hugo --minify`.
    4. Deploys the artifact directly to GitHub Pages.

**Important:** Do not manually push to the `gh-pages` branch. The workflow handles the publication artifact.

## 🤝 Context & Maintenance

- **Content Language:** English.
- **Key Topics:** AWS, Azure, Kubernetes, HIPAA, SBOM, ARO.
- **Inventory:** Check `CONTENT_INVENTORY.md` for a list of tracked content.

---
*Author: Gustavo de Oliveira Ferreira*
