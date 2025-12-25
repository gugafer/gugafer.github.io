# Kubernetes Security Baselines for Regulated Industries

> Implementing Pod Security Standards, Network Policies, and Policy-as-Code for FedRAMP, NIST SP 800-53, and CMMC compliance in Kubernetes environments.

**Author:** Gustavo de Oliveira Ferreira
**Date:** December 2025
**Tags:** Kubernetes, Security, FedRAMP, NIST, CMMC, Policy-as-Code, DevSecOps

---

## Introduction

Organizations operating Kubernetes clusters in regulated environments face complex compliance requirements:

- **FedRAMP:** Federal Risk and Authorization Management Program for cloud services used by federal agencies
- **NIST SP 800-53:** Security and Privacy Controls for Information Systems
- **CMMC 2.0:** Cybersecurity Maturity Model Certification for DoD contractors (effective December 2024)
- **NIST SP 800-171:** Protecting Controlled Unclassified Information (CUI)
- **PCI DSS:** Payment Card Industry Data Security Standard
- **HIPAA:** Health Insurance Portability and Accountability Act

This guide provides actionable security baselines based on production deployments in healthcare, financial services, and government-adjacent workloads, with direct mapping to federal compliance frameworks.

### Why Kubernetes Security is Different

Kubernetes introduces unique security challenges:

1. **Dynamic Infrastructure:** Pods are ephemeral; traditional perimeter security doesn't apply
2. **Shared Responsibility:** Security spans cluster operators, platform teams, and application developers
3. **Complex Attack Surface:** API server, etcd, kubelet, container runtime, network plugins
4. **Configuration Complexity:** Hundreds of settings that can introduce vulnerabilities

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

### Security Controls by Layer

| Layer | Controls | Tools |
|-------|----------|-------|
| **Cluster** | API server hardening, etcd encryption, audit logging | kubeadm, EKS/AKS/GKE configs |
| **Node** | CIS benchmarks, OS hardening, runtime security | Falco, Sysdig, kube-bench |
| **Network** | Network policies, service mesh, mTLS | Calico, Istio, Cilium |
| **Workload** | Pod Security Standards, RBAC, secrets | OPA Gatekeeper, Kyverno, Vault |
| **Supply Chain** | Image scanning, SBOM, signing | Trivy, Cosign, SLSA |

---

## NIST SP 800-53 Mapping for Kubernetes

The following table maps NIST SP 800-53 Rev 5 controls to Kubernetes implementations:

### Access Control (AC)

| NIST Control | Description | Kubernetes Implementation |
|--------------|-------------|---------------------------|
| **AC-2** | Account Management | RBAC, ServiceAccounts, OIDC integration |
| **AC-3** | Access Enforcement | RBAC, Namespace isolation, Network Policies |
| **AC-4** | Information Flow Enforcement | Network Policies, Service Mesh |
| **AC-5** | Separation of Duties | RBAC with least privilege, separate namespaces |
| **AC-6** | Least Privilege | Pod Security Standards, drop ALL capabilities |
| **AC-17** | Remote Access | API server authentication, kubectl audit |

### Audit and Accountability (AU)

| NIST Control | Description | Kubernetes Implementation |
|--------------|-------------|---------------------------|
| **AU-2** | Audit Events | API server audit policy |
| **AU-3** | Content of Audit Records | Structured audit logs (JSON) |
| **AU-6** | Audit Review, Analysis | Falco, Sentinel, Splunk |
| **AU-9** | Protection of Audit Information | Immutable log storage, separate access |
| **AU-12** | Audit Generation | Kubernetes audit webhook |

### Configuration Management (CM)

| NIST Control | Description | Kubernetes Implementation |
|--------------|-------------|---------------------------|
| **CM-2** | Baseline Configuration | Pod Security Standards, CIS benchmarks |
| **CM-6** | Configuration Settings | Admission controllers, GitOps |
| **CM-7** | Least Functionality | Distroless images, read-only filesystem |
| **CM-8** | Component Inventory | SBOM, container registry scanning |

### System and Communications Protection (SC)

| NIST Control | Description | Kubernetes Implementation |
|--------------|-------------|---------------------------|
| **SC-7** | Boundary Protection | Network Policies, ingress controllers |
| **SC-8** | Transmission Confidentiality | mTLS (Istio/Linkerd), TLS termination |
| **SC-13** | Cryptographic Protection | Secrets encryption, etcd encryption |
| **SC-28** | Protection of Information at Rest | Encrypted PVs, etcd encryption at rest |

### System and Information Integrity (SI)

| NIST Control | Description | Kubernetes Implementation |
|--------------|-------------|---------------------------|
| **SI-3** | Malicious Code Protection | Image scanning, admission control |
| **SI-4** | Information System Monitoring | Falco, Prometheus, Grafana |
| **SI-7** | Software Integrity | Image signing (Cosign), admission verification |

---

## Pod Security Standards Implementation

Kubernetes 1.25+ includes built-in Pod Security Standards (PSS) that replace the deprecated PodSecurityPolicy.

### Security Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| **Privileged** | Unrestricted | System workloads (CNI, CSI drivers) |
| **Baseline** | Minimally restrictive | General workloads, compatibility |
| **Restricted** | Heavily restricted | Security-sensitive workloads, compliance |

### Namespace Configuration

Apply Pod Security Standards at the namespace level using labels:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production-workloads
  labels:
    # Enforce restricted baseline (most secure)
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest

    # Warn on violations (for visibility during migration)
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest

    # Audit all violations (for compliance logging)
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
```

### Restricted Pod Example

A pod that complies with the `restricted` security standard:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  namespace: production-workloads
spec:
  # Pod-level security context
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault

  # Prevent privilege escalation at pod level
  hostNetwork: false
  hostPID: false
  hostIPC: false

  containers:
    - name: app
      # Use digest for immutable reference
      image: myregistry.azurecr.io/app:v1.2.3@sha256:abc123def456...

      # Container-level security context
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        runAsNonRoot: true
        runAsUser: 1000
        capabilities:
          drop:
            - ALL
        seccompProfile:
          type: RuntimeDefault

      # Resource limits (prevent DoS)
      resources:
        limits:
          cpu: "500m"
          memory: "256Mi"
          ephemeral-storage: "1Gi"
        requests:
          cpu: "100m"
          memory: "128Mi"

      # Health probes
      livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
        initialDelaySeconds: 10
        periodSeconds: 10

      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 5

      # Writable directories (since rootfs is read-only)
      volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/cache

  volumes:
    - name: tmp
      emptyDir:
        sizeLimit: 100Mi
    - name: cache
      emptyDir:
        sizeLimit: 500Mi

  # Service account with minimal permissions
  serviceAccountName: app-service-account
  automountServiceAccountToken: false  # Disable if not needed
```

---

## Policy-as-Code with OPA Gatekeeper

[OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper) extends Kubernetes admission control with custom policies written in Rego.

### Install Gatekeeper

```bash
# Helm installation
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm install gatekeeper/gatekeeper --name-template=gatekeeper --namespace gatekeeper-system --create-namespace

# Verify installation
kubectl get pods -n gatekeeper-system
```

### Constraint Template: Require Image Signatures

Ensure all container images are signed:

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequireimagesignatures
  annotations:
    description: "Requires container images to be from approved registries"
spec:
  crd:
    spec:
      names:
        kind: K8sRequireImageSignatures
      validation:
        openAPIV3Schema:
          type: object
          properties:
            allowedRegistries:
              description: "List of allowed container registries"
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequireimagesignatures

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not image_from_allowed_registry(container.image)
          msg := sprintf("Container image '%v' is not from an allowed registry. Allowed: %v", [container.image, input.parameters.allowedRegistries])
        }

        violation[{"msg": msg}] {
          container := input.review.object.spec.initContainers[_]
          not image_from_allowed_registry(container.image)
          msg := sprintf("Init container image '%v' is not from an allowed registry. Allowed: %v", [container.image, input.parameters.allowedRegistries])
        }

        image_from_allowed_registry(image) {
          allowed := input.parameters.allowedRegistries[_]
          startswith(image, allowed)
        }
```

### Constraint: Apply to All Namespaces

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequireImageSignatures
metadata:
  name: require-approved-registries
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces:
      - kube-system
      - gatekeeper-system
      - calico-system
  parameters:
    allowedRegistries:
      - "myregistry.azurecr.io/"
      - "mcr.microsoft.com/"
      - "docker.io/library/"  # Official images only
```

### Constraint Template: Require Resource Limits

Prevent resource exhaustion attacks:

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequireresourcelimits
spec:
  crd:
    spec:
      names:
        kind: K8sRequireResourceLimits
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequireresourcelimits

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.cpu
          msg := sprintf("Container '%v' must have CPU limits", [container.name])
        }

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.memory
          msg := sprintf("Container '%v' must have memory limits", [container.name])
        }
```

---

## Network Policies for Zero Trust

Network Policies implement microsegmentation — the foundation of Zero Trust networking.

### Default Deny All Traffic

Start with a deny-all baseline, then explicitly allow required traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}  # Applies to all pods in namespace
  policyTypes:
    - Ingress
    - Egress
```

### Allow DNS Resolution

All pods need DNS access:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

### Allow Frontend to Backend Communication

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
      tier: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
              tier: web
      ports:
        - protocol: TCP
          port: 8080
```

### Allow Backend to Database

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: database
      tier: data
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: backend
              tier: api
      ports:
        - protocol: TCP
          port: 5432  # PostgreSQL
```

### Allow Egress to External Services (Controlled)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-external-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
      needs-external-access: "true"
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 10.0.0.0/8      # Block internal ranges
              - 172.16.0.0/12
              - 192.168.0.0/16
      ports:
        - protocol: TCP
          port: 443
```

---

## Audit Logging Configuration

Kubernetes API server audit logs are essential for compliance and incident response.

### API Server Audit Policy

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Don't log read-only requests to certain endpoints
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
      - group: ""
        resources: ["endpoints", "services", "services/status"]

  # Don't log kubelet health checks
  - level: None
    users: ["kubelet"]
    verbs: ["get"]
    resources:
      - group: ""
        resources: ["nodes", "nodes/status"]

  # Log all requests to secrets at RequestResponse level
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["secrets", "configmaps"]

  # Log pod exec/attach at Request level (sensitive operations)
  - level: Request
    resources:
      - group: ""
        resources: ["pods/exec", "pods/attach", "pods/portforward"]

  # Log all changes to RBAC
  - level: RequestResponse
    resources:
      - group: "rbac.authorization.k8s.io"
        resources:
          - "roles"
          - "rolebindings"
          - "clusterroles"
          - "clusterrolebindings"

  # Log namespace operations
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["namespaces"]

  # Log service account token requests
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["serviceaccounts/token"]

  # Log admission webhook configurations
  - level: RequestResponse
    resources:
      - group: "admissionregistration.k8s.io"
        resources:
          - "validatingwebhookconfigurations"
          - "mutatingwebhookconfigurations"

  # Default: log metadata for everything else
  - level: Metadata
    omitStages:
      - RequestReceived
```

### Audit Log Storage (Azure Log Analytics)

```yaml
# Fluentd ConfigMap for Azure Log Analytics
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: kube-system
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/kubernetes/audit/audit.log
      pos_file /var/log/kubernetes/audit/audit.log.pos
      tag kubernetes.audit
      format json
      time_key timestamp
    </source>

    <match kubernetes.audit>
      @type azure-loganalytics
      customer_id "#{ENV['WORKSPACE_ID']}"
      shared_key "#{ENV['WORKSPACE_KEY']}"
      log_type KubernetesAudit
    </match>
```

---

## Runtime Security with Falco

[Falco](https://falco.org/) provides real-time threat detection for containers and Kubernetes.

### Install Falco

```bash
# Helm installation
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --namespace falco-system \
  --create-namespace \
  --set falcosidekick.enabled=true \
  --set falcosidekick.webui.enabled=true
```

### Custom Falco Rules for Compliance

```yaml
# falco-rules.yaml
customRules:
  rules-compliance.yaml: |-
    # Detect crypto mining
    - rule: Detect Crypto Mining
      desc: Detect crypto mining processes
      condition: >
        spawned_process and
        (proc.name in (xmrig, minerd, cpuminer, cgminer, bfgminer) or
         proc.cmdline contains "stratum+tcp" or
         proc.cmdline contains "cryptonight" or
         proc.cmdline contains "monero")
      output: >
        Crypto mining detected (user=%user.name command=%proc.cmdline
        container=%container.name image=%container.image.repository
        namespace=%k8s.ns.name pod=%k8s.pod.name)
      priority: CRITICAL
      tags: [cryptomining, mitre_execution, T1496]

    # Detect sensitive file access
    - rule: Sensitive File Access
      desc: Detect access to sensitive files
      condition: >
        open_read and
        fd.name in (/etc/shadow, /etc/passwd, /etc/kubernetes/pki/ca.crt,
                    /etc/kubernetes/pki/apiserver.key, /var/run/secrets/kubernetes.io/serviceaccount/token)
      output: >
        Sensitive file accessed (user=%user.name file=%fd.name
        container=%container.name namespace=%k8s.ns.name pod=%k8s.pod.name)
      priority: WARNING
      tags: [filesystem, mitre_credential_access, T1552]

    # Detect shell spawned in container
    - rule: Shell Spawned in Container
      desc: Detect shell execution in container (potential reverse shell)
      condition: >
        spawned_process and
        container and
        proc.name in (bash, sh, zsh, dash, ash, ksh) and
        not proc.pname in (containerd-shim, runc, crio)
      output: >
        Shell spawned in container (user=%user.name shell=%proc.name parent=%proc.pname
        container=%container.name image=%container.image.repository
        namespace=%k8s.ns.name pod=%k8s.pod.name)
      priority: WARNING
      tags: [shell, mitre_execution, T1059]

    # Detect kubectl exec
    - rule: Kubectl Exec Detected
      desc: Detect kubectl exec into pod
      condition: >
        spawned_process and
        container and
        proc.pname = "runc" and
        proc.name != "pause"
      output: >
        Kubectl exec detected (user=%user.name command=%proc.cmdline
        container=%container.name namespace=%k8s.ns.name pod=%k8s.pod.name)
      priority: NOTICE
      tags: [kubectl, mitre_execution]

    # Detect network tool usage (potential data exfiltration)
    - rule: Network Tool Execution in Container
      desc: Detect network reconnaissance or data exfiltration tools
      condition: >
        spawned_process and
        container and
        proc.name in (nc, ncat, netcat, nmap, wget, curl, dig, nslookup, tcpdump, wireshark)
      output: >
        Network tool executed in container (user=%user.name command=%proc.cmdline
        container=%container.name namespace=%k8s.ns.name pod=%k8s.pod.name)
      priority: WARNING
      tags: [network, mitre_discovery, mitre_exfiltration]
```

### Falco Alert Integration (Slack/PagerDuty)

```yaml
# falcosidekick configuration
falcosidekick:
  config:
    slack:
      webhookurl: "https://hooks.slack.com/services/XXX/YYY/ZZZ"
      minimumpriority: "warning"
      outputformat: "all"
    pagerduty:
      apikey: "YOUR_PAGERDUTY_KEY"
      minimumpriority: "critical"
```

---

## Compliance Automation

### Continuous Compliance Scanning with Trivy Operator

[Trivy Operator](https://github.com/aquasecurity/trivy-operator) provides continuous vulnerability scanning and compliance reporting.

```bash
# Install Trivy Operator
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm install trivy-operator aqua/trivy-operator \
  --namespace trivy-system \
  --create-namespace \
  --set trivy.ignoreUnfixed=true
```

### Compliance Report CRD

```yaml
apiVersion: aquasecurity.github.io/v1alpha1
kind: ClusterComplianceReport
metadata:
  name: nist-sp-800-53
spec:
  cron: "0 */6 * * *"  # Every 6 hours
  reportType: summary
  compliance:
    id: nist-sp-800-53
    title: "NIST SP 800-53"
    description: "NIST Security and Privacy Controls"
    version: "5.0"
```

### CIS Kubernetes Benchmark with kube-bench

```bash
# Run CIS benchmark scan
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml

# View results
kubectl logs job/kube-bench
```

### Automated CIS Scanning (CronJob)

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kube-bench-scan
  namespace: security-scanning
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: kube-bench
              image: aquasec/kube-bench:latest
              command: ["kube-bench", "--json"]
              volumeMounts:
                - name: results
                  mountPath: /results
          volumes:
            - name: results
              persistentVolumeClaim:
                claimName: kube-bench-results
          restartPolicy: OnFailure
          nodeSelector:
            node-role.kubernetes.io/control-plane: ""
          tolerations:
            - key: node-role.kubernetes.io/control-plane
              effect: NoSchedule
```

---

## Best Practices Summary

### 1. Start with Restricted Pod Security Standards

```bash
# Apply restricted baseline to all new namespaces by default
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted
kubectl label namespace default pod-security.kubernetes.io/warn=restricted
kubectl label namespace default pod-security.kubernetes.io/audit=restricted
```

### 2. Network Policies First

Implement default-deny before deploying workloads:

```bash
# Create deny-all policy in every namespace
for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
  kubectl apply -n $ns -f default-deny-all.yaml
done
```

### 3. Shift Left — Scan in CI/CD

Scan images in CI/CD, not just at deployment:

```yaml
# GitHub Actions example
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.IMAGE_NAME }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail pipeline on critical/high
```

### 4. Continuous Monitoring

Runtime detection catches what static analysis misses:

| Tool | Purpose | Alert Destination |
|------|---------|-------------------|
| Falco | Runtime threat detection | Slack, PagerDuty, SIEM |
| Trivy Operator | Continuous vulnerability scanning | Prometheus/Grafana |
| Prometheus | Metrics and alerting | AlertManager |

### 5. Audit Everything

API server audit logs are essential for incident response:

```bash
# Search audit logs for suspicious activity
kubectl logs -n kube-system kube-apiserver-* | \
  jq 'select(.verb == "create" and .objectRef.resource == "secrets")'
```

---

## CMMC 2.0 Specific Considerations

With [CMMC 2.0](https://www.acq.osd.mil/cmmc/) effective December 2024, DoD contractors must implement NIST SP 800-171 controls:

| CMMC Practice | Kubernetes Implementation |
|---------------|---------------------------|
| AC.L2-3.1.1 | RBAC with least privilege |
| AC.L2-3.1.2 | Transaction restrictions via admission controllers |
| AU.L2-3.3.1 | API server audit logging |
| AU.L2-3.3.2 | Unique user IDs via OIDC |
| CM.L2-3.4.1 | CIS benchmarks, Pod Security Standards |
| SC.L2-3.13.1 | Network Policies, mTLS |
| SC.L2-3.13.8 | Encryption at rest (etcd, PVs) |

---

## Conclusion

Securing Kubernetes for regulated industries requires a defense-in-depth approach across all layers. Key takeaways:

1. **Pod Security Standards:** Enforce `restricted` baseline for all workloads
2. **Network Policies:** Default deny, explicit allow
3. **Policy-as-Code:** Gatekeeper/Kyverno for admission control
4. **Runtime Security:** Falco for threat detection
5. **Audit Logging:** Complete audit trail for compliance
6. **Continuous Scanning:** Automated vulnerability and compliance scanning

This guide provides a foundation aligned with FedRAMP and NIST requirements but should be tailored to your specific compliance framework and risk profile.

---

## References

- [NIST SP 800-53 Rev 5](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-53r5.pdf)
- [NIST SP 800-171 Rev 2](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-171r2.pdf)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [CISA Zero Trust Maturity Model](https://www.cisa.gov/zero-trust-maturity-model)
- [NSA/CISA Kubernetes Hardening Guide](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)
- [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper)
- [Falco](https://falco.org/)
- [Trivy](https://github.com/aquasecurity/trivy)
- [CMMC 2.0 Model](https://www.acq.osd.mil/cmmc/)

---

*This article is part of a series on cloud security and DevSecOps best practices for regulated industries.*
