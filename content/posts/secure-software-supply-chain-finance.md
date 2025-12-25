---
title: "Secure Software Supply Chain in the Financial Sector"
date: 2025-07-18T10:00:00
draft: false
author: "Gustavo de Oliveira Ferreira"
tags: ["DevSecOps", "Finance", "SBOM", "Supply Chain Security", "Compliance"]
categories: ["Security", "Finance"]
description: "Implementing SBOM and artifact signing in CI/CD pipelines for financial institutions."
---

## Introduction

The financial sector is a prime target for cyberattacks, and software supply chain security became a critical concern following incidents like SolarWinds. Ensuring the integrity and provenance of the software we use and deliver is fundamental. My experience at major financial institutions like Serasa Experian and Banco Bradesco provided insights into how DevSecOps practices, specifically Software Bill of Materials (SBOM) Generation and Artifact Signing, are crucial for building a more resilient software supply chain.

This article details the importance and implementation of these practices in a CI/CD environment, aligning with federal mandates like US Executive Order 14028.

## The Threat Landscape: Software Supply Chain Attacks

A software supply chain attack occurs when an attacker introduces malicious code or vulnerabilities into upstream software components, which are then distributed to end-users. For financial institutions, this can have devastating consequences, including data theft, service disruption, and reputational damage.

## The DevSecOps Solution: SBOM and Artifact Signing

We integrated SBOM generation and artifact signing directly into our CI/CD pipelines to automate and enforce these safeguards.

### 1. Software Bill of Materials (SBOM) Generation

An SBOM is like a complete ingredients list for a software product. It lists all open-source and proprietary components, their versions, licenses, and any dependencies.

*   **How We Implemented It:**
    *   We used tools like **Syft** and **Trivy** integrated into our GitLab CI/CD pipeline to analyze build artifacts and automatically generate SBOMs in SPDX and CycloneDX formats.
    *   **Benefit:** Full component visibility allowed us to quickly identify known vulnerabilities (CVEs) and manage risks proactively.

### 2. Artifact Signing and Provenance

Artifact signing ensures the integrity and authenticity of software by verifying it hasn't been tampered with since build time and comes from a trusted source.

*   **How We Implemented It:**
    *   We integrated **Sigstore/Cosign** into our pipelines to digitally sign container images and other artifacts. Signing keys were securely managed with a KMS (Key Management Service).
    *   We implemented checks in deployment environments ensuring that **only signed and verified artifacts** could be deployed to production.
    *   **Benefit:** Prevented the deployment of unauthorized or tampered software, providing a critical layer of trust in the supply chain.

## Conclusion

Software supply chain security is an ongoing battle, but the automated implementation of SBOM, artifact signing, and policy-as-code in CI/CD pipelines offers robust defense. In the financial sector, where data trust and integrity are paramount, these practices are not just "nice to have"—they are absolutely essential.

---
*Gustavo de Oliveira Ferreira is a DevSecOps and Cloud specialist with extensive experience implementing software supply chain security practices in mission-critical environments.*
