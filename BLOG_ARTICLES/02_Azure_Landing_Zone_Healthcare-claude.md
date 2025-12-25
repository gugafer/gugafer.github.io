# Azure Landing Zone Architecture for Healthcare: HIPAA-Compliant Cloud Foundations

> A comprehensive guide to deploying Azure Landing Zones with built-in HIPAA compliance, identity governance, and network segmentation for healthcare organizations.

**Author:** Gustavo de Oliveira Ferreira
**Date:** December 2025
**Tags:** Azure, Landing Zone, Healthcare, HIPAA, Compliance, Infrastructure as Code, Terraform

---

## Introduction

Healthcare organizations migrating to Azure face unique compliance challenges:

- **HIPAA** (Health Insurance Portability and Accountability Act) requirements
- **PHI** (Protected Health Information) data handling obligations
- **BAA** (Business Associate Agreement) contractual requirements
- **HITRUST CSF** certification considerations
- State-specific healthcare regulations (e.g., California CMIA, Texas HB 300)

This guide presents a Landing Zone architecture proven in **Fortune 40 healthcare environments**, incorporating Azure-native security controls mapped to HIPAA Technical Safeguards.

### Why Landing Zones Matter

A Landing Zone is not just infrastructure — it's a **governance foundation** that ensures:

1. **Consistency:** Every workload inherits the same security baseline
2. **Compliance:** Controls are built-in, not bolted-on
3. **Scalability:** New subscriptions automatically inherit policies
4. **Auditability:** Centralized logging enables compliance reporting

---

## What is an Azure Landing Zone?

An Azure Landing Zone is a pre-configured, secure cloud environment that provides:

| Component | Purpose | Azure Services |
|-----------|---------|----------------|
| **Identity Foundation** | Authentication, authorization, privileged access | Azure AD, RBAC, PIM |
| **Network Topology** | Segmentation, connectivity, traffic inspection | Virtual Networks, Azure Firewall, ExpressRoute |
| **Security Baseline** | Threat protection, policy enforcement | Defender for Cloud, Azure Policy, Sentinel |
| **Governance** | Resource organization, cost management | Management Groups, Subscriptions, Tags |
| **Operations** | Monitoring, logging, backup, DR | Azure Monitor, Log Analytics, Recovery Services |

### Azure Landing Zone Accelerator

Microsoft provides the [Azure Landing Zone Accelerator](https://github.com/Azure/Enterprise-Scale) (formerly Enterprise-Scale) as a reference implementation. This guide extends that foundation with **healthcare-specific controls**.

---

## HIPAA Compliance Mapping

The HIPAA Security Rule (45 CFR Part 164) defines Technical Safeguards that must be addressed:

### Technical Safeguards Mapping

| HIPAA Requirement | CFR Reference | Azure Control | Implementation |
|-------------------|---------------|---------------|----------------|
| **Access Control** | §164.312(a)(1) | Azure AD + Conditional Access | MFA, device compliance, risk-based access |
| **Unique User Identification** | §164.312(a)(2)(i) | Azure AD | Named accounts, no shared credentials |
| **Emergency Access** | §164.312(a)(2)(ii) | Break-glass accounts | PIM with emergency access procedures |
| **Automatic Logoff** | §164.312(a)(2)(iii) | Conditional Access | Session timeout policies |
| **Encryption/Decryption** | §164.312(a)(2)(iv) | Azure Disk Encryption, TDE | CMK with Key Vault |
| **Audit Controls** | §164.312(b) | Azure Monitor + Log Analytics | Centralized logging, 6-year retention |
| **Integrity Controls** | §164.312(c)(1) | Azure Backup + Immutable Storage | WORM storage, soft delete |
| **Authentication** | §164.312(d) | Azure AD + MFA | Phishing-resistant MFA (FIDO2) |
| **Transmission Security** | §164.312(e)(1) | TLS 1.2+ + Private Endpoints | No public endpoints for PHI |

### Administrative Safeguards (Technical Implementation)

| Requirement | Azure Implementation |
|-------------|---------------------|
| Security Management Process | Defender for Cloud Secure Score, Azure Policy compliance |
| Workforce Security | Azure AD Identity Governance, Access Reviews |
| Information Access Management | RBAC, Attribute-Based Access Control (ABAC) |
| Security Awareness Training | Defender for Office 365 attack simulation |
| Security Incident Procedures | Sentinel playbooks, automated response |
| Contingency Plan | Azure Site Recovery, geo-redundant backups |

---

## Architecture Overview

### Management Group Hierarchy

```
Tenant Root Group
│
├── Platform
│   ├── Identity
│   │   └── [Identity Subscription]
│   │       ├── Azure AD Connect (if hybrid)
│   │       ├── Azure AD Domain Services
│   │       └── Privileged Identity Management
│   │
│   ├── Management
│   │   └── [Management Subscription]
│   │       ├── Log Analytics Workspace (central)
│   │       ├── Automation Account
│   │       ├── Azure Monitor
│   │       └── Microsoft Sentinel
│   │
│   └── Connectivity
│       └── [Connectivity Subscription]
│           ├── Hub Virtual Network
│           ├── Azure Firewall (Premium)
│           ├── ExpressRoute Gateway
│           ├── VPN Gateway
│           └── Azure DDoS Protection
│
├── Landing Zones
│   ├── Corp
│   │   └── [Internal Workloads]
│   │
│   ├── Online
│   │   └── [Public-facing - Non-PHI]
│   │
│   └── Healthcare ◄── HIPAA-specific policies
│       ├── [PHI Workloads Subscription]
│       │   ├── Spoke VNet (peered to Hub)
│       │   ├── Private Endpoints only
│       │   ├── Customer-Managed Keys
│       │   └── Enhanced audit logging
│       │
│       └── [Clinical Applications Subscription]
│           └── ...
│
├── Sandbox
│   └── [Dev/Test - No PHI allowed]
│
└── Decommissioned
    └── [Retired subscriptions]
```

### Network Topology: Hub-Spoke with Private Endpoints

```
                                    ┌─────────────────────────────────────┐
                                    │           On-Premises               │
                                    │         Data Center                 │
                                    └──────────────┬──────────────────────┘
                                                   │
                                         ExpressRoute / VPN
                                                   │
                                    ┌──────────────▼──────────────────────┐
                                    │         Hub Virtual Network          │
                                    │            10.0.0.0/16               │
                                    │                                      │
                                    │  ┌─────────────────────────────┐    │
                                    │  │     Azure Firewall          │    │
                                    │  │     (Premium SKU)           │    │
                                    │  │     - TLS Inspection        │    │
                                    │  │     - IDPS                  │    │
                                    │  │     - URL Filtering         │    │
                                    │  └─────────────────────────────┘    │
                                    │                                      │
                                    │  ┌─────────────────────────────┐    │
                                    │  │     Azure Bastion           │    │
                                    │  │     (No public RDP/SSH)     │    │
                                    │  └─────────────────────────────┘    │
                                    │                                      │
                                    └──────────────┬──────────────────────┘
                                                   │
                         ┌─────────────────────────┼─────────────────────────┐
                         │                         │                         │
              ┌──────────▼──────────┐   ┌─────────▼─────────┐   ┌──────────▼──────────┐
              │   Healthcare Spoke   │   │    Corp Spoke     │   │    Online Spoke     │
              │    10.1.0.0/16       │   │   10.2.0.0/16     │   │    10.3.0.0/16      │
              │                      │   │                   │   │                     │
              │  ┌────────────────┐  │   │                   │   │                     │
              │  │ Private        │  │   │                   │   │                     │
              │  │ Endpoints Only │  │   │                   │   │                     │
              │  │ - SQL          │  │   │                   │   │                     │
              │  │ - Storage      │  │   │                   │   │                     │
              │  │ - Key Vault    │  │   │                   │   │                     │
              │  └────────────────┘  │   │                   │   │                     │
              │                      │   │                   │   │                     │
              │  [PHI Workloads]     │   │  [Internal Apps]  │   │  [Public Web Apps]  │
              └─────────────────────-┘   └───────────────────┘   └─────────────────────┘
```

---

## Infrastructure as Code Implementation

### Terraform Module Structure

```
healthcare-landing-zone/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars
│
├── modules/
│   ├── management-groups/
│   ├── policy-assignments/
│   ├── hub-network/
│   ├── spoke-network/
│   ├── log-analytics/
│   ├── key-vault/
│   └── private-endpoints/
│
└── policies/
    ├── hipaa-baseline/
    ├── encryption-requirements/
    └── network-restrictions/
```

### Main Configuration

```hcl
# main.tf - Healthcare Landing Zone

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatehealthcare"
    container_name       = "tfstate"
    key                  = "healthcare-landing-zone.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false  # HIPAA: retain deleted keys
    }
  }
}

# -----------------------------------------------------------------------------
# Management Groups
# -----------------------------------------------------------------------------
module "management_groups" {
  source = "./modules/management-groups"

  root_management_group_name = "Healthcare-Organization"

  management_groups = {
    platform = {
      display_name = "Platform"
      children = {
        identity     = { display_name = "Identity" }
        management   = { display_name = "Management" }
        connectivity = { display_name = "Connectivity" }
      }
    }
    landing_zones = {
      display_name = "Landing Zones"
      children = {
        healthcare = { display_name = "Healthcare" }  # PHI workloads
        corp       = { display_name = "Corp" }
        online     = { display_name = "Online" }
      }
    }
    sandbox = {
      display_name = "Sandbox"
    }
  }
}

# -----------------------------------------------------------------------------
# Hub Network (Connectivity Subscription)
# -----------------------------------------------------------------------------
module "hub_network" {
  source = "./modules/hub-network"

  resource_group_name = "rg-connectivity-hub"
  location            = var.primary_location

  vnet_name           = "vnet-hub-${var.primary_location}"
  vnet_address_space  = ["10.0.0.0/16"]

  subnets = {
    AzureFirewallSubnet = {
      address_prefixes = ["10.0.1.0/26"]
    }
    AzureBastionSubnet = {
      address_prefixes = ["10.0.2.0/26"]
    }
    GatewaySubnet = {
      address_prefixes = ["10.0.3.0/27"]
    }
  }

  # Azure Firewall Configuration
  firewall_sku_tier = "Premium"  # Required for TLS inspection, IDPS
  enable_idps       = true
  idps_mode         = "Deny"     # Block known threats

  # DDoS Protection
  enable_ddos_protection = true

  tags = var.common_tags
}

# -----------------------------------------------------------------------------
# Healthcare Spoke Network
# -----------------------------------------------------------------------------
module "healthcare_spoke" {
  source = "./modules/spoke-network"

  resource_group_name = "rg-healthcare-network"
  location            = var.primary_location

  vnet_name          = "vnet-healthcare-${var.primary_location}"
  vnet_address_space = ["10.1.0.0/16"]

  subnets = {
    snet-workloads = {
      address_prefixes                          = ["10.1.1.0/24"]
      private_endpoint_network_policies_enabled = true
      service_endpoints                         = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.KeyVault"]
    }
    snet-private-endpoints = {
      address_prefixes                          = ["10.1.2.0/24"]
      private_endpoint_network_policies_enabled = false  # Required for Private Endpoints
    }
    snet-aks = {
      address_prefixes = ["10.1.4.0/22"]  # /22 for AKS node pools
    }
  }

  # Peer to Hub
  hub_vnet_id               = module.hub_network.vnet_id
  hub_vnet_name             = module.hub_network.vnet_name
  hub_resource_group_name   = module.hub_network.resource_group_name

  # Route all traffic through Azure Firewall
  route_table_routes = {
    default = {
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.hub_network.firewall_private_ip
    }
  }

  tags = var.common_tags
}

# -----------------------------------------------------------------------------
# Centralized Log Analytics (Management Subscription)
# -----------------------------------------------------------------------------
module "log_analytics" {
  source = "./modules/log-analytics"

  resource_group_name = "rg-management-logging"
  location            = var.primary_location

  workspace_name      = "law-healthcare-central"
  sku                 = "PerGB2018"

  # HIPAA: 6-year retention requirement
  retention_in_days   = 365  # Hot storage

  # Archive to Storage for long-term retention
  enable_archive             = true
  archive_retention_days     = 2190  # 6 years
  archive_storage_account_id = module.archive_storage.id

  # Disable public access for security
  internet_ingestion_enabled = false
  internet_query_enabled     = false

  # Private Link for secure ingestion
  enable_private_link = true
  private_link_subnet_id = module.hub_network.subnet_ids["snet-private-endpoints"]

  tags = var.common_tags
}

# -----------------------------------------------------------------------------
# Key Vault with HSM-backed keys (CMK for PHI encryption)
# -----------------------------------------------------------------------------
module "key_vault" {
  source = "./modules/key-vault"

  resource_group_name = "rg-healthcare-security"
  location            = var.primary_location

  key_vault_name      = "kv-healthcare-${var.environment}"
  sku_name            = "premium"  # HSM-backed keys

  # Access Configuration
  enable_rbac_authorization = true  # Use RBAC instead of access policies

  # Network Security
  public_network_access_enabled = false

  # Soft delete and purge protection (HIPAA requirement)
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  # Private Endpoint
  private_endpoint_subnet_id = module.healthcare_spoke.subnet_ids["snet-private-endpoints"]

  # Diagnostic Settings
  diagnostic_settings = {
    log_analytics_workspace_id = module.log_analytics.workspace_id
    logs                       = ["AuditEvent", "AzurePolicyEvaluationDetails"]
    metrics                    = ["AllMetrics"]
  }

  tags = var.common_tags
}

# -----------------------------------------------------------------------------
# Azure Policy Assignments - HIPAA Baseline
# -----------------------------------------------------------------------------
module "policy_assignments" {
  source = "./modules/policy-assignments"

  # Assign to Healthcare Management Group
  management_group_id = module.management_groups.healthcare_mg_id

  policy_assignments = {
    # Built-in HIPAA/HITRUST initiative
    hipaa-hitrust = {
      policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/a169a624-5599-4385-a696-c8d643089fab"
      display_name         = "HIPAA HITRUST 9.2"
      enforcement_mode     = "Default"
    }

    # Require encryption at rest
    require-encryption = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0961003e-5a0a-4549-abde-af6a37f2724d"
      display_name         = "Require encryption on Data Lake Store"
      enforcement_mode     = "Default"
    }

    # Require HTTPS
    require-https-storage = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
      display_name         = "Secure transfer to storage accounts"
      enforcement_mode     = "Default"
    }

    # Require Private Endpoints for SQL
    require-private-endpoint-sql = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/7698e800-9299-47a6-b3b6-5a0fee576eed"
      display_name         = "Private endpoint for SQL Server"
      enforcement_mode     = "Default"
    }

    # Deny public IP addresses
    deny-public-ip = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/6c112d4e-5bc7-47ae-a041-ea2d9dccd749"
      display_name         = "Deny public IP addresses"
      enforcement_mode     = "Default"
    }
  }
}

# -----------------------------------------------------------------------------
# Microsoft Sentinel (SIEM)
# -----------------------------------------------------------------------------
module "sentinel" {
  source = "./modules/sentinel"

  resource_group_name          = "rg-management-security"
  location                     = var.primary_location
  log_analytics_workspace_id   = module.log_analytics.workspace_id
  log_analytics_workspace_name = module.log_analytics.workspace_name

  # Data Connectors
  enable_azure_ad_connector           = true
  enable_azure_activity_connector     = true
  enable_defender_for_cloud_connector = true
  enable_office_365_connector         = true

  # Analytics Rules (HIPAA-relevant)
  analytics_rules = {
    brute-force-detection = {
      display_name = "Brute Force Attack Detection"
      severity     = "High"
      query        = <<-QUERY
        SigninLogs
        | where ResultType == "50126"
        | summarize FailedAttempts = count() by UserPrincipalName, IPAddress, bin(TimeGenerated, 1h)
        | where FailedAttempts > 10
      QUERY
      frequency    = "PT1H"
      period       = "PT1H"
    }
    phi-access-anomaly = {
      display_name = "Anomalous PHI Access Pattern"
      severity     = "Medium"
      query        = <<-QUERY
        AzureDiagnostics
        | where ResourceType == "SERVERS/DATABASES"
        | where Category == "SQLSecurityAuditEvents"
        | where statement_s contains "patient" or statement_s contains "diagnosis"
        | summarize AccessCount = count() by caller_id_s, bin(TimeGenerated, 1h)
        | where AccessCount > 100
      QUERY
      frequency    = "PT1H"
      period       = "PT24H"
    }
  }

  tags = var.common_tags
}

# -----------------------------------------------------------------------------
# Defender for Cloud
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "defender_plans" {
  for_each = toset([
    "VirtualMachines",
    "SqlServers",
    "AppServices",
    "StorageAccounts",
    "KeyVaults",
    "Arm",
    "Dns",
    "Containers"
  ])

  tier          = "Standard"
  resource_type = each.value
}

resource "azurerm_security_center_auto_provisioning" "auto_provision" {
  auto_provision = "On"
}
```

### Variables Configuration

```hcl
# variables.tf

variable "primary_location" {
  description = "Primary Azure region for deployment"
  type        = string
  default     = "eastus2"
}

variable "secondary_location" {
  description = "Secondary Azure region for DR"
  type        = string
  default     = "centralus"
}

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment     = "Production"
    DataClass       = "PHI"
    Compliance      = "HIPAA"
    ManagedBy       = "Terraform"
    CostCenter      = "Healthcare-IT"
  }
}
```

---

## Private Endpoints for PHI Data

All Azure PaaS services handling PHI must use Private Endpoints to eliminate public internet exposure.

### Azure SQL with Private Endpoint

```hcl
# Private Endpoint for Azure SQL (PHI Database)
resource "azurerm_private_endpoint" "sql_phi" {
  name                = "pe-sql-phi-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.healthcare_spoke.subnet_ids["snet-private-endpoints"]

  private_service_connection {
    name                           = "psc-sql-phi"
    private_connection_resource_id = azurerm_mssql_server.phi.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }

  tags = var.common_tags
}

# Private DNS Zone for SQL
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

# Link DNS Zone to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql_hub" {
  name                  = "link-sql-hub"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = module.hub_network.vnet_id
  registration_enabled  = false
}

# Link DNS Zone to Healthcare Spoke
resource "azurerm_private_dns_zone_virtual_network_link" "sql_healthcare" {
  name                  = "link-sql-healthcare"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = module.healthcare_spoke.vnet_id
  registration_enabled  = false
}
```

### Storage Account with Private Endpoint

```hcl
resource "azurerm_storage_account" "phi_storage" {
  name                     = "stphidata${var.environment}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"  # Geo-redundant for DR

  # Security Configuration
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false  # Private Endpoint only

  # Encryption
  infrastructure_encryption_enabled = true  # Double encryption

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 365  # HIPAA retention
    }

    container_delete_retention_policy {
      days = 90
    }
  }

  # Customer-Managed Key
  identity {
    type = "SystemAssigned"
  }

  tags = var.common_tags
}

# Enable CMK encryption
resource "azurerm_storage_account_customer_managed_key" "phi_cmk" {
  storage_account_id = azurerm_storage_account.phi_storage.id
  key_vault_id       = module.key_vault.id
  key_name           = azurerm_key_vault_key.storage_encryption.name
}

# Private Endpoint for Blob
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-storage-blob-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.healthcare_spoke.subnet_ids["snet-private-endpoints"]

  private_service_connection {
    name                           = "psc-storage-blob"
    private_connection_resource_id = azurerm_storage_account.phi_storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}
```

---

## Monitoring and Incident Response

### Diagnostic Settings for All Resources

```hcl
# Diagnostic settings module for consistent logging
resource "azurerm_monitor_diagnostic_setting" "all_resources" {
  for_each = var.monitored_resources

  name                       = "diag-${each.key}"
  target_resource_id         = each.value.id
  log_analytics_workspace_id = module.log_analytics.workspace_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

### Activity Log Export (Subscription-level)

```hcl
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "diag-activity-log"
  target_resource_id         = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  log_analytics_workspace_id = module.log_analytics.workspace_id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Policy"
  }
}
```

---

## Best Practices Summary

### 1. Defense in Depth

```
┌─────────────────────────────────────────────────────────────┐
│                     Identity Layer                          │
│  Azure AD + MFA + Conditional Access + PIM                  │
├─────────────────────────────────────────────────────────────┤
│                     Network Layer                           │
│  NSGs + Azure Firewall + Private Endpoints + DDoS          │
├─────────────────────────────────────────────────────────────┤
│                     Compute Layer                           │
│  Defender for Servers + Endpoint Protection + Patching     │
├─────────────────────────────────────────────────────────────┤
│                     Data Layer                              │
│  Encryption (CMK) + TDE + Backup + Classification          │
├─────────────────────────────────────────────────────────────┤
│                     Application Layer                       │
│  WAF + API Management + Code Scanning + DAST               │
└─────────────────────────────────────────────────────────────┘
```

### 2. Zero Trust Principles

| Principle | Implementation |
|-----------|----------------|
| **Verify Explicitly** | Conditional Access with device compliance, risk signals |
| **Least Privilege** | PIM for just-in-time access, RBAC with minimal permissions |
| **Assume Breach** | Sentinel for threat detection, micro-segmentation |

### 3. Automation

- **Infrastructure as Code:** All resources defined in Terraform
- **Policy as Code:** Azure Policy for continuous compliance
- **Compliance as Code:** Defender for Cloud for drift detection

### 4. Incident Readiness

- Pre-configure Sentinel playbooks for common scenarios
- Document incident response procedures
- Regular tabletop exercises
- Automated alerting to security team

---

## Conclusion

A well-architected Azure Landing Zone provides the foundation for HIPAA-compliant healthcare workloads. Key takeaways:

1. **Start with governance:** Management groups and policies before workloads
2. **Private by default:** All PHI services behind Private Endpoints
3. **Encrypt everything:** CMK for data at rest, TLS 1.2+ in transit
4. **Log everything:** 6-year retention for HIPAA audit requirements
5. **Automate compliance:** Azure Policy + Defender for continuous assessment

This guide demonstrates patterns proven in enterprise healthcare environments but should be adapted to your organization's specific requirements and risk tolerance.

---

## References

- [Microsoft Cloud for Healthcare](https://docs.microsoft.com/en-us/industry/healthcare/)
- [Azure HIPAA/HITRUST Blueprint](https://docs.microsoft.com/en-us/azure/governance/blueprints/samples/hipaa-hitrust-9-2)
- [Azure Landing Zone Accelerator](https://github.com/Azure/Enterprise-Scale)
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/index.html)
- [NIST SP 800-66 — HIPAA Security Rule Implementation](https://csrc.nist.gov/publications/detail/sp/800-66/rev-2/final)
- [Azure Well-Architected Framework — Security](https://docs.microsoft.com/en-us/azure/architecture/framework/security/)
- [Microsoft Compliance Documentation](https://docs.microsoft.com/en-us/compliance/)

---

*This article is part of a series on cloud security and compliance for regulated industries.*
