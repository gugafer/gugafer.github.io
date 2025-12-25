--- 
title: "Implementing Software Bill of Materials (SBOM) in Enterprise CI/CD Pipelines"
date: 2025-11-15T10:00:00
draft: false
author: "Gustavo de Oliveira Ferreira"
tags: ["DevSecOps", "Software Supply Chain", "SBOM", "CI/CD", "Compliance"]
categories: ["Security", "DevOps"]
description: "A practical guide for implementing SBOM generation, artifact signing, and provenance tracking in enterprise environments."
---

> A practical guide for implementing SBOM generation, artifact signing, and provenance tracking in enterprise environments, aligned with Executive Order 14028 requirements.

## Introduction

[Executive Order 14028](https://www.govinfo.gov/content/pkg/FR-2021-05-17/pdf/2021-10460.pdf) (May 2021) mandates that federal agencies and their software suppliers implement software supply chain security measures, including:

- Software Bill of Materials (SBOM) generation
- Artifact signing and provenance verification
- Secure software development practices

The urgency of these requirements was underscored by high-profile supply chain attacks:

- **SolarWinds (2020):** Compromised build system affected 18,000+ organizations including federal agencies
- **Log4Shell (2021):** CVE-2021-44228 exposed the challenge of identifying affected components across enterprise software portfolios
- **Codecov (2021):** CI/CD pipeline compromise demonstrated supply chain attack vectors

This article provides a hands-on implementation guide based on real-world enterprise deployments in healthcare, financial services, and telecommunications sectors.

--- 

## What is an SBOM?

An SBOM is a formal, machine-readable inventory of software components and dependencies. Think of it as a "nutritional label" for software — it lists every ingredient (library, framework, dependency) that goes into your application.

### Key SBOM Formats

| Format | Standard Body | Strengths |
|--------|---------------|-----------|
| **SPDX** | Linux Foundation | ISO/IEC 5962:2021 standard, comprehensive license tracking |
| **CycloneDX** | OWASP | Security-focused, vulnerability correlation, lightweight |
| **SWID Tags** | ISO/IEC 19770-2 | Enterprise asset management integration |

### NTIA Minimum Elements

Per [NTIA guidance](https://www.ntia.gov/sites/default/files/publications/sbom_minimum_elements_report_0.pdf), an SBOM must include:

1. **Supplier Name** — Entity that creates, defines, and identifies components
2. **Component Name** — Designation assigned to a unit of software
3. **Version of the Component** — Identifier used by supplier to specify a change
4. **Other Unique Identifiers** — Other identifiers used to identify a component (PURL, CPE)
5. **Dependency Relationship** — Characterizing the relationship (e.g., X includes Y)
6. **Author of SBOM Data** — Entity that creates the SBOM data
7. **Timestamp** — Record of the date and time of the SBOM data assembly

--- 

## Why SBOMs Matter for Critical Infrastructure

### The Log4Shell Case Study

When CVE-2021-44228 (Log4Shell) was disclosed in December 2021, organizations faced a critical question: *"Where in our software portfolio is Log4j used?"*

Organizations **with** SBOMs could:
- Query their SBOM database within minutes
- Identify affected applications, containers, and servers
- Prioritize patching based on exposure and criticality

Organizations **without** SBOMs had to:
- Manually scan thousands of applications
- Search through dependency trees of unknown depth
- Spend weeks identifying exposure

**Bottom line:** SBOMs transform incident response from days/weeks to minutes/hours.

### Federal Mandate Timeline

| Date | Milestone |
|------|-----------|
| May 2021 | EO 14028 signed |
| November 2021 | NIST defines "critical software" |
| September 2022 | OMB M-22-18 requires attestation from software producers |
| 2023-2024 | Federal agencies begin requiring SBOMs from vendors |
| December 2024 | CMMC 2.0 effective — supply chain security mandatory for DoD contractors |

--- 

## Implementation Architecture

### Pipeline Overview

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   BUILD     │───▶│    SCAN     │───▶│    SIGN     │───▶│   PUBLISH   │───▶│   DEPLOY    │
│             │    │             │    │             │    │             │    │             │
│ Generate    │    │ Vuln scan   │    │ Cosign/     │    │ Store SBOM  │    │ Verify      │
│ SBOM (Syft) │    │ (Grype)     │    │ Sigstore    │    │ + artifact  │    │ signatures  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Components

| Stage | Tool | Purpose |
|-------|------|---------|
| Generate | [Syft](https://github.com/anchore/syft) | Create SBOM from container images, filesystems |
| Scan | [Grype](https://github.com/anchore/grype) | Vulnerability scanning against SBOM |
| Sign | [Cosign](https://github.com/sigstore/cosign) | Keyless signing via Sigstore |
| Store | OCI Registry / Artifactory | Artifact + SBOM storage with attestations |
| Verify | Cosign / Kyverno | Admission-time signature verification |

--- 

## Hands-On Implementation

### Step 1: SBOM Generation with Syft

#### Install Syft

```bash
# macOS/Linux
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Verify installation
syft version
```

#### Generate SBOM from Container Image

```bash
# CycloneDX JSON format (recommended for security use cases)
syft myregistry.azurecr.io/myapp:v1.2.3 -o cyclonedx-json > sbom.json

# SPDX format (for license compliance)
syft myregistry.azurecr.io/myapp:v1.2.3 -o spdx-json > sbom-spdx.json

# View in human-readable table
syft myregistry.azurecr.io/myapp:v1.2.3 -o table
```

#### GitHub Actions Integration

```yaml
name: Build and Generate SBOM

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Container Image
        run: docker build -t ${{ env.IMAGE_NAME }}:${{ github.sha }} .

      - name: Generate SBOM
        uses: anchore/sbom-action@v0
        with:
          image: ${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: cyclonedx-json
          output-file: sbom.cyclonedx.json

      - name: Upload SBOM as Artifact
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: sbom.cyclonedx.json
```

### Step 2: Vulnerability Scanning with Grype

#### Install Grype

```bash
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

#### Scan SBOM for Vulnerabilities

```bash
# Basic scan
grype sbom:sbom.cyclonedx.json

# Fail on high/critical vulnerabilities (for CI/CD gates)
grype sbom:sbom.cyclonedx.json --fail-on high

# Output as JSON for further processing
grype sbom:sbom.cyclonedx.json -o json > vulnerabilities.json
```

#### CI/CD Gate Example

```yaml
- name: Scan SBOM for Vulnerabilities
  run: |
    grype sbom:sbom.cyclonedx.json --fail-on critical
  continue-on-error: false
```

### Step 3: Artifact Signing with Cosign

Cosign enables cryptographic signing of container images and attestations, providing provenance verification.

#### Install Cosign

```bash
# macOS
brew install cosign

# Linux
curl -O -L https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64
mv cosign-linux-amd64 /usr/local/bin/cosign
```

#### Keyless Signing (Recommended)

Keyless signing uses Sigstore's Fulcio CA and Rekor transparency log — no key management required.

```bash
# Sign the container image (keyless via OIDC)
cosign sign $IMAGE_NAME:$TAG

# Attach SBOM to the image
cosign attach sbom --sbom sbom.cyclonedx.json $IMAGE_NAME:$TAG

# Create and sign an SBOM attestation
cosign attest --predicate sbom.cyclonedx.json --type cyclonedx $IMAGE_NAME:$TAG
```

#### Key-Based Signing (Air-Gapped Environments)

```bash
# Generate key pair
cosign generate-key-pair

# Sign with private key
cosign sign --key cosign.key $IMAGE_NAME:$TAG

# Verify with public key
cosign verify --key cosign.pub $IMAGE_NAME:$TAG
```

### Step 4: Complete Azure DevOps Pipeline

```yaml
trigger:
  branches:
    include:
      - main
      - release/*

variables:
  imageName: 'myregistry.azurecr.io/myapp'
  tag: '$(Build.BuildId)'

stages:
  - stage: Build
    displayName: 'Build and Scan'
    jobs:
      - job: BuildJob
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: Docker@2
            displayName: 'Build Container Image'
            inputs:
              containerRegistry: 'AzureContainerRegistry'
              repository: 'myapp'
              command: 'build'
              Dockerfile: '**/Dockerfile'
              tags: '$(tag)'

          - script: |
              curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
              syft $(imageName):$(tag) -o cyclonedx-json > $(Build.ArtifactStagingDirectory)/sbom.json
            displayName: 'Generate SBOM'

          - script: |
              curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
              grype sbom:$(Build.ArtifactStagingDirectory)/sbom.json --fail-on critical
            displayName: 'Vulnerability Scan'

          - script: |
              curl -O -L https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
              chmod +x cosign-linux-amd64
              ./cosign-linux-amd64 sign --key $(COSIGN_PRIVATE_KEY) $(imageName):$(tag)
              ./cosign-linux-amd64 attest --key $(COSIGN_PRIVATE_KEY) --predicate $(Build.ArtifactStagingDirectory)/sbom.json --type cyclonedx $(imageName):$(tag)
            displayName: 'Sign Image and Attest SBOM'
            env:
              COSIGN_PRIVATE_KEY: $(CosignPrivateKey)
              COSIGN_PASSWORD: $(CosignPassword)

          - task: Docker@2
            displayName: 'Push to Registry'
            inputs:
              containerRegistry: 'AzureContainerRegistry'
              repository: 'myapp'
              command: 'push'
              tags: '$(tag)'

          - publish: $(Build.ArtifactStagingDirectory)/sbom.json
            artifact: sbom
            displayName: 'Publish SBOM Artifact'
```

--- 

## Enterprise Considerations

### Policy Enforcement with Kyverno

Enforce SBOM and signature requirements at Kubernetes admission time:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-image-signatures
spec:
  validationFailureAction: Enforce
  background: false
  rules:
    - name: verify-signature
      match:
        any:
          - resources:
              kinds:
                - Pod
      verifyImages:
        - imageReferences:
            - "myregistry.azurecr.io/*"
          attestors:
            - count: 1
              entries:
                - keys:
                    publicKeys: |-
                      -----BEGIN PUBLIC KEY-----
                      MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
                      -----END PUBLIC KEY-----
```

### Storage and Retention

| Requirement | Implementation |
|-------------|----------------|
| **Centralized Storage** | Store SBOMs in artifact repository (JFrog Artifactory, AWS ECR, Azure ACR) alongside images |
| **Retention Period** | Regulated industries: 7+ years (HIPAA, PCI DSS); align with software lifecycle |
| **Searchability** | Index SBOMs in a database (DependencyTrack, GUAC) for CVE impact queries |
| **Access Control** | Restrict SBOM access to security/compliance teams; avoid exposing dependency details publicly |

### Dependency-Track Integration

[Dependency-Track](https://dependencytrack.org/) provides continuous SBOM analysis:

```bash
# Upload SBOM to Dependency-Track via API
curl -X POST "https://dependencytrack.example.com/api/v1/bom" \
  -H "X-Api-Key: $DT_API_KEY" \
  -H "Content-Type: application/vnd.cyclonedx+json" \
  -d @sbom.cyclonedx.json
```

--- 

## Alignment with Federal Standards

| Requirement | EO 14028 Section | Implementation |
|-------------|------------------|----------------|
| SBOM for critical software | Section 4(e) | Syft + CycloneDX |
| Provenance verification | Section 4(e)(ix) | Cosign + Sigstore/Rekor |
| Vulnerability disclosure | Section 4(d) | Grype + OSV database |
| Integrity verification | Section 4(e)(iii) | Image digests + attestations |
| Secure development attestation | Section 4(e)(i) | SLSA framework adoption |

### SLSA Framework Alignment

[SLSA](https://slsa.dev/) (Supply-chain Levels for Software Artifacts) provides a maturity model:

| SLSA Level | Requirements | Tools |
|------------|--------------|-------|
| Level 1 | Documentation of build process | Build scripts in version control |
| Level 2 | Tamper-resistant build service | GitHub Actions, Azure Pipelines |
| Level 3 | Hardened build platform, provenance | Sigstore, in-toto attestations |
| Level 4 | Hermetic, reproducible builds | Bazel, Nix |

--- 

## Conclusion

Implementing SBOM in your CI/CD pipeline is no longer optional for organizations serving federal agencies or critical infrastructure sectors. The combination of:

- **Syft** for SBOM generation
- **Grype** for vulnerability scanning
- **Cosign** for signing and attestation

...provides a foundation that can be adapted to your specific toolchain and compliance requirements.

### Key Takeaways

1. **Start Now:** Federal requirements are already in effect; don't wait for an RFP to demand SBOMs
2. **Automate Everything:** SBOMs must be generated on every build, not manually
3. **Sign and Attest:** Unsigned SBOMs have limited value; cryptographic provenance is essential
4. **Store and Index:** SBOMs are only useful if you can query them during incidents
5. **Enforce at Admission:** Use Kyverno/Gatekeeper to block unsigned images

--- 

## References

- [Executive Order 14028 — Improving the Nation's Cybersecurity](https://www.govinfo.gov/content/pkg/FR-2021-05-17/pdf/2021-10460.pdf)
- [NTIA SBOM Minimum Elements](https://www.ntia.gov/sites/default/files/publications/sbom_minimum_elements_report_0.pdf)
- [CISA SBOM Sharing Guidance](https://www.cisa.gov/sbom)
- [Syft Documentation](https://github.com/anchore/syft)
- [Grype Documentation](https://github.com/anchore/grype)
- [Cosign Documentation](https://github.com/sigstore/cosign)
- [SLSA Framework](https://slsa.dev/)
- [Dependency-Track](https://dependencytrack.org/)
- [NIST SP 800-218 — Secure Software Development Framework](https://csrc.nist.gov/publications/detail/sp/800-218/final)

--- 

*This article is part of a series on cloud security and DevSecOps best practices for regulated industries.*
