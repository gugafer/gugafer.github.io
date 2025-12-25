---
title: "Kubernetes Security Baselines for Regulated Industries"
date: 2025-09-10T10:00:00
draft: false
author: "Gustavo de Oliveira Ferreira"
tags: ["Kubernetes", "Security", "FedRAMP", "NIST", "CMMC", "DevSecOps"]
categories: ["Cloud Native", "Security"]
description: "Implementing Pod Security Standards, Network Policies, and Policy-as-Code for FedRAMP, NIST SP 800-53, and CMMC compliance."
---

> Implementing Pod Security Standards, Network Policies, and Policy-as-Code for FedRAMP, NIST SP 800-53, and CMMC compliance in Kubernetes environments.

## Introduction

Organizations operating Kubernetes clusters in regulated environments face complex compliance requirements:

- **FedRAMP:** Federal Risk and Authorization Management Program
- **NIST SP 800-53:** Security and Privacy Controls for Information Systems
- **CMMC 2.0:** Cybersecurity Maturity Model Certification for DoD contractors
- **PCI DSS:** Payment Card Industry Data Security Standard
- **HIPAA:** Health Insurance Portability and Accountability Act

This guide provides actionable security baselines based on production deployments in healthcare, financial services, and government-adjacent workloads.

---

## Kubernetes Security Layers

Security must be implemented at every layer of the stack:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Supply Chain Layer                           │
│  Image scanning, SBOM, signing, base image hardening               │
├─────────────────────────────────────────────────────────────────────┤
│                        Workload Layer                               │
│  Pod Security Standards, RBAC, secrets management, resource limits │
├─────────────────────────────────────────────────────────────────────┤
│                        Network Layer                                │
│  Network Policies, service mesh (mTLS), ingress/egress controls    │
├─────────────────────────────────────────────────────────────────────┤
│                        Node Layer                                   │
│  CIS benchmarks, OS hardening, runtime security (Falco)            │
├─────────────────────────────────────────────────────────────────────┤
│                        Cluster Layer                                │
│  API server hardening, etcd encryption, audit logging, RBAC        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Pod Security Standards Implementation

Kubernetes 1.25+ includes built-in Pod Security Standards (PSS) that replace the deprecated PodSecurityPolicy.

### Namespace Configuration

Apply Pod Security Standards at the namespace level using labels:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production-workloads
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/audit: restricted
```

### Restricted Pod Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: myregistry.azurecr.io/app:v1.2.3
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]
```

---

## Network Policies for Zero Trust

Network Policies implement microsegmentation — the foundation of Zero Trust networking.

### Default Deny All Traffic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes: ["Ingress", "Egress"]
```

---

## Runtime Security with Falco

[Falco](https://falco.org/) provides real-time threat detection for containers and Kubernetes.

### Custom Falco Rules for Compliance

```yaml
- rule: Detect Crypto Mining
  condition: >
    spawned_process and
    (proc.name in (xmrig, minerd, cpuminer) or
     proc.cmdline contains "stratum+tcp")
  output: "Crypto mining detected (user=%user.name command=%proc.cmdline)"
  priority: CRITICAL
```

---

## Best Practices Summary

1. **Pod Security Standards:** Enforce `restricted` baseline for all workloads.
2. **Network Policies:** Default deny, explicit allow.
3. **Policy-as-Code:** Gatekeeper/Kyverno for admission control.
4. **Runtime Security:** Falco for threat detection.
5. **Audit Logging:** Complete audit trail for compliance.
6. **Continuous Scanning:** Automated vulnerability and compliance scanning.

---

## References

- [NIST SP 800-53 Rev 5](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-53r5.pdf)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [NSA/CISA Kubernetes Hardening Guide](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)

---

*This article is part of a series on cloud security and DevSecOps best practices for regulated industries.*
