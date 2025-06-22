# gugafer.github.io
Personal gugafer page and blog.

# ✅ Hugo + PaperMod + GitHub Pages Deployment Checklist

Este checklist descreve os passos necessários para configurar e manter um blog com Hugo + PaperMod utilizando GitHub Pages com deploy automático via GitHub Actions.

---

## 🔧 Requisitos

* Conta GitHub
* Tema: [hugo-PaperMod](https://github.com/adityatelange/hugo-PaperMod)
* Hugo instalado localmente (preferencialmente a mesma versão do GitHub Action: `v0.125.7+` ou superior)

---

## 🏁 Etapas de Configuração Inicial

### 1. Criar o Repositório GitHub

* Nome sugerido: `gugafer.github.io`
* Habilitar GitHub Pages em: `Settings > Pages > Source: GitHub Actions`

### 2. Inicializar Projeto Hugo

```bash
hugo new site gugafer.github.io
```

### 3. Adicionar o Tema como Submódulo

```bash
git submodule add https://github.com/adityatelange/hugo-PaperMod.git themes/hugo-PaperMod
```

### 4. Atualizar `config.yaml`

```yaml
title: "Gustavo gugafer"
baseURL: "https://gugafer.github.io/"
theme: "hugo-PaperMod"
paginate: 5
languageCode: "en-us"
...
```

> ✅ Sugestão: Utilize `YAML` ao invés de `TOML` se preferir.

### 5. Atualizar `.gitignore`

```bash
/public/
resources/_gen/
```

---

## ✅ Criar Conteúdo Markdown

```bash
hugo new posts/nome-do-artigo.md
```

Edite os arquivos em `content/posts/` com seu editor preferido.

---

## 🤖 CI/CD com GitHub Actions

### 1. Crie `.github/workflows/deploy.yml`

```yaml
name: Deploy no GitHub Pages com Hugo + PaperMod

on:
  push:
    branches: [ main ]

permissions:
  contents: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: 🚀 Checkout do Código
        uses: actions/checkout@v4
        with:
          submodules: true
          fetch-depth: 0

      - name: 🌐 Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.125.7'
          extended: true

      - name: ⚙️ Gerar o Site Estático
        run: hugo --minify

      - name: 🌟 Deploy no GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

---

## 🔄 Atualizar Tema (PaperMod)

```bash
cd themes/hugo-PaperMod
git pull origin master
cd ../..
```

---

## 🌍 Verifique a Publicação

Acesse: **[https://gugafer.github.io](https://gugafer.github.io)**

Se desejar, personalize a homepage, modos (`home-info`, `profile`, `regular`) e SEO em `config.yaml` conforme preferência.

---
