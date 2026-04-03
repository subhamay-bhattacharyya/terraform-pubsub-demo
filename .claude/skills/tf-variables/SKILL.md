---
name: tf-variables
description: >
  Use this skill whenever working with Terraform variables.tf files on GCP
  projects — for both root modules and child/reusable modules. Trigger this
  skill when the user wants to: write new variable blocks from scratch; review
  or audit an existing variables.tf; add or fix validation blocks; generate
  .tfvars files from a variable schema; write module call blocks that pass
  variable values; understand when to use root vs child module variable
  patterns; or debug type constraint errors. Also trigger when the user pastes
  a variables.tf, a .tfvars, or a module call block and asks how to improve,
  fill in, or fix it — regardless of whether they mention "skill" or
  "variables.tf" by name. Covers GCP-specific field types, naming conventions,
  and common map-based patterns.
---

# Terraform Variables — GCP Skill

Covers authoring, validating, and consuming `variables.tf` for GCP projects,
across both **root modules** (entry-point configs) and **child modules**
(reusable building blocks). Variable values are passed via `.tfvars` files.

---

## Quick Decision Guide

| Situation | Go to |
|---|---|
| Writing a new `variables.tf` | Authoring Patterns |
| Root vs child module trade-offs | Root vs Child Module Variables |
| Adding or fixing validations | Validation Patterns |
| Generating a `.tfvars` file | Generating .tfvars |
| Generating input JSON config files | Generating Input JSON Config Files |
| Writing a module call block | Module Call Blocks |
| GCP field types / allowed values | GCP Reference |

---

## Canonical variables.tf Template

Every root module in this project follows this structure. The first two
variables (`environment` and `project_code`) are **mandatory in all configs**
— they drive resource naming and environment targeting. Service-specific
variables (like `service_config_path`) follow, then infrastructure variables
(`credentials_file`, `project_id`, `region`).

```hcl
# -- tf/variables.tf

# -- The two variables environment and project_code are must for all Terraform
# -- configurations. They are used for naming resources and defining the
# -- environment in which the infrastructure will be deployed.

variable "environment" {
  description = "Environment name (devl, test, prod)"
  type        = string
  default     = "devl"

  validation {
    condition     = contains(["devl", "test", "prod"], var.environment)
    error_message = "Environment must be devl, test, or prod."
  }
}

variable "project_code" {
  description = "Project code prefix for resource naming (e.g., snw-lkh)"
  type        = string
  default     = "snw"
}

# Configuration File Paths
# ============================================================================

variable "service_config_path" {
  description = "Map of config keys to <service> config JSON file paths"
  type        = map(string)
  default = {
    basic   = "<service>_basic.json"
    basic_1 = "<service>_basic_1.json"
    basic_2 = "<service>_basic_2.json"
  }
}

variable "credentials_file" {
  description = "Path to the GCP service account credentials JSON file"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID in which resources will be created."
  type        = string
}

variable "region" {
  description = "GCP region for provider configuration (e.g., us-central1)"
  type        = string
}
```

**Rules for this template:**
- `environment` and `project_code` always come first, always include their
  comment block header.
- `environment` always has the three-value validation (`devl`, `test`, `prod`).
- `credentials_file`, `project_id`, and `region` are always required (no
  default) — values come from environment-specific `.tfvars`.
- `service_config_path` keys follow the `basic`, `basic_1`, `basic_2` pattern;
  add more keys as needed for the service.

---

## Authoring Patterns

### Required vs Optional Fields

| Pattern | When to Use |
|---|---|
| `type = string` (no default) | Always required — caller must supply via `.tfvars` |
| `default = "value"` | Has a sensible default; can be overridden |
| `default = null` | Truly optional; resource skips it when null |
| `default = {}` / `default = []` | Optional map/list, empty by default |

### Map of Config Paths Pattern

Use `map(string)` when the module reads multiple JSON config files, one per
logical resource instance. Keys are short identifiers; values are file paths.

```hcl
variable "service_config_path" {
  description = "Map of config keys to Cloud SQL config JSON file paths"
  type        = map(string)
  default = {
    basic   = "cloud_sql_basic.json"
    basic_1 = "cloud_sql_basic_1.json"
  }
}
```

### Map-Based Object Config Pattern (inline config, no JSON files)

Use `map(object({...}))` when resource config lives in Terraform directly
rather than in JSON files. The variable name follows the convention
**`<service_name>_config`** — replace `<service_name>` with the GCP service
being configured (e.g. `gcs_bucket_config`, `cloud_sql_config`,
`pubsub_topic_config`). The map key is a Terraform state identifier — always
include an explicit `name` field for the actual GCP resource name.

```hcl
# Example for GCS — variable is named gcs_bucket_config
variable "gcs_bucket_config" {
  description = "Map of GCS bucket configurations, keyed by logical name."
  type = map(object({
    name                        = string
    location                    = optional(string, "US")
    storage_class               = optional(string, "STANDARD")
    uniform_bucket_level_access = optional(bool, true)
    versioning_enabled          = optional(bool, false)
    labels                      = optional(map(string), {})
  }))
  default = {}
}

# Example for Cloud SQL — variable is named cloud_sql_config
variable "cloud_sql_config" {
  description = "Map of Cloud SQL instance configurations, keyed by logical name."
  type = map(object({
    name             = string
    database_version = optional(string, "POSTGRES_15")
    tier             = optional(string, "db-f1-micro")
    region           = optional(string, "us-central1")
    deletion_protection = optional(bool, true)
  }))
  default = {}
}
```

**Naming rule:** always `<service_name>_config`, never generic names like
`resource_configs` or `bucket_configs`. Use the GCP service name as the
prefix: `gcs_bucket`, `cloud_sql`, `pubsub_topic`, `bigquery_dataset`,
`cloud_run_service`, etc.

### Sensitive Variables

Mark variables that hold secrets so Terraform redacts them in plan output:

```hcl
variable "db_password" {
  description = "Database password. Do not commit the value to source control."
  type        = string
  sensitive   = true
}
```

---

## Root vs Child Module Variables

### Root Module (`tf/variables.tf`)

- Always start with `environment` and `project_code` (mandatory pair).
- Keep types simple (`string`, `map(string)`) — these are the operator interface.
- Infrastructure variables (`project_id`, `region`, `credentials_file`) are
  always required with no default; values come from `.tfvars`.
- Group variables with `# Section` comment blocks.

### Child Module (`modules/<name>/variables.tf`)

- Variables are the interface to other Terraform code — use precise complex
  types (`object`, `map(object(...))`) to enforce structure at plan time.
- Avoid `any` types; they defer type errors to runtime.
- Don't re-declare `project_id` / `region` if the module inherits them via
  provider alias — only declare what the module genuinely needs as input.

```hcl
variable "network_config" {
  description = "VPC network configuration."
  type = object({
    network_name             = string
    subnetwork_name          = string
    region                   = optional(string, "us-central1")
    private_ip_google_access = optional(bool, true)
  })
}
```

---

## Validation Patterns

Validations run at `terraform plan` time, before any API calls.

```hcl
# Non-empty string
validation {
  condition     = length(var.project_id) > 0
  error_message = "project_id must not be empty."
}

# Enum / allowed values
validation {
  condition     = contains(["us-central1", "us-east1", "europe-west1", "asia-east1"], var.region)
  error_message = "region must be one of: us-central1, us-east1, europe-west1, asia-east1."
}

# Map values enum (e.g. storage_class on each entry in gcs_bucket_config)
validation {
  condition = alltrue([
    for k, v in var.gcs_bucket_config :
    contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], v.storage_class)
  ])
  error_message = "storage_class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
}

# Numeric range
validation {
  condition     = var.min_cpu_platform >= 1 && var.min_cpu_platform <= 96
  error_message = "min_cpu_platform must be between 1 and 96."
}

# Label key format (GCP requires lowercase, hyphens/underscores only)
validation {
  condition = alltrue([
    for k in keys(var.labels) : can(regex("^[a-z][a-z0-9_-]{0,62}$", k))
  ])
  error_message = "Label keys must start with a lowercase letter and contain only lowercase letters, numbers, hyphens, or underscores."
}
```

---

## Generating .tfvars

> CRITICAL — file naming and location rules. Do not deviate:
> - Name is ALWAYS `auto.terraform.tfvars.json` — NEVER `<env>.terraform.tfvars.json`
> - Parent directory is ALWAYS `environments` (plural) — NEVER `environment` (singular)
> - Each environment gets its OWN subdirectory: `tf/environments/devl/`, `tf/environments/test/`, `tf/environments/prod/`

**Directory structure:**

```
tf/
└── environments/
    ├── devl/
    │   └── auto.terraform.tfvars.json
    ├── test/
    │   └── auto.terraform.tfvars.json
    └── prod/
        └── auto.terraform.tfvars.json
```

**Rules:**
1. File format is JSON, not HCL.
2. File name is always `auto.terraform.tfvars.json` — never `<env>.terraform.tfvars.json`.
3. Each file lives in its own `tf/environments/<env>/` subdirectory.
4. JSON keys are the **exact variable names** from `variables.tf` — no renaming.
5. `service_config_path` is a JSON object with keys matching the map keys
   in the `variables.tf` default (e.g. `basic`, `basic_1`, `basic_2`).
6. All required variables must be present: `environment`, `project_code`,
   `<service_name>_config_path`, `credentials_file`, `project_id`, `region`.

Example for `devl` with `service_name = gcs_bucket`, `project_code = gcsdemo`:

```json
{
  "environment": "devl",
  "project_code": "gcsdemo",
  "gcs_config_path": {
    "basic": "gcs_bucket_basic.json"
  },
  "credentials_file": "sa-key/sa-key.json",
  "project_id": "prj-17-cloud-storage-16748",
  "region": "us-central1"
}
```

Repeat for `test` and `prod`, substituting the appropriate `environment`
value. Keep all other keys identical unless the user specifies overrides.

---

## Generating Input JSON Config Files

After generating `variables.tf`, create one service config JSON file per
environment under `input-jsons/<env>/<service_name>_config.json`, where
`<service_name>` is the GCP service from argument `$0`.

**Directory layout:**

```
input-jsons/
├── devl/
│   └── <service_name>_config.json
├── test/
│   └── <service_name>_config.json
└── prod/
    └── <service_name>_config.json
```

**Rules:**
1. File name is `<service_name>_config.json` — derived from `$0`.
2. JSON keys map directly to the variable names declared in `variables.tf`
   for the `<service_name>_config` variable's object schema.
3. Populate values with sensible environment-appropriate defaults.
4. Omit `environment` and `project_code` — those come from
   `auto.terraform.tfvars.json`, not from the config JSON.

Example for `service_name = gcs_bucket`, derived from the `gcs_bucket_config`
object schema in `variables.tf`:

```json
{
  "name": "gcsdemo-devl-bucket",
  "location": "US",
  "storage_class": "STANDARD",
  "force_destroy": false,
  "uniform_bucket_level_access": true,
  "public_access_prevention": "enforced",
  "versioning_enabled": false,
  "labels": {
    "managed_by": "terraform"
  }
}
```

For `prod`, use production-appropriate values (e.g. `versioning_enabled: true`,
stricter retention). For `test`, mirror `devl` unless the user specifies
otherwise.

---

## Module Call Blocks

When writing a `module` block that calls a child module, the variable name
in the call matches the `<service_name>_config` convention declared in the
child module's `variables.tf`:

```hcl
# Calling a GCS module — variable is gcs_bucket_config
module "gcs" {
  source = "./modules/gcs"

  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  project_code = var.project_code

  gcs_bucket_config = {
    data_lake = {
      name               = "my-company-data-lake"
      location           = "US"
      versioning_enabled = true
    }
    artifacts = {
      name          = "my-company-artifacts"
      storage_class = "NEARLINE"
    }
  }
}

# Calling a Cloud SQL module — variable is cloud_sql_config
module "cloud_sql" {
  source = "./modules/cloud_sql"

  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  project_code = var.project_code

  cloud_sql_config = {
    primary = {
      name             = "my-app-db"
      database_version = "POSTGRES_15"
      tier             = "db-g1-small"
    }
  }
}
```

Always pass `environment` and `project_code` through to child modules —
they are required for consistent resource naming. Pass root-module variables
via `var.*` rather than hardcoding values.

---

## GCP Reference

### Common Variable Types

| Variable | Type | Notes |
|---|---|---|
| `project_id` | `string` | GCP project ID string (not number) |
| `region` | `string` | e.g. `us-central1`, `europe-west1` |
| `zone` | `string` | e.g. `us-central1-a` |
| `network` | `string` | VPC name or self-link |
| `subnetwork` | `string` | Subnet name or self-link |
| `machine_type` | `string` | e.g. `e2-micro`, `n2-standard-4` |
| `labels` | `map(string)` | Keys/values must be lowercase |
| `service_account_email` | `string` | `name@project.iam.gserviceaccount.com` |
| `image_family` | `string` | e.g. `debian-11`, `ubuntu-2204-lts` |

### Common Regions

`us-central1`, `us-east1`, `us-east4`, `us-west1`, `us-west2`,
`northamerica-northeast1`, `europe-west1`, `europe-west2`, `europe-west4`,
`asia-east1`, `asia-southeast1`, `australia-southeast1`

### GCS Storage Classes

| Class | Use Case |
|---|---|
| `STANDARD` | Frequently accessed data |
| `NEARLINE` | Access < once per month |
| `COLDLINE` | Access < once per quarter |
| `ARCHIVE` | Access < once per year |

### Label Constraints

- Keys and values must be **lowercase**
- Keys: start with a letter, max 63 chars, `[a-z0-9_-]` only
- Max **64 labels** per resource
- Values: max 63 chars, can be empty string

### Common Mistakes

- **Using project number instead of project ID** — most GCP resources need the
  string ID (`my-project-123`), not the numeric project number.
- **Uppercase in labels** — GCP rejects them; always validate label keys.
- **Hardcoding region in child modules** — pass it as a variable so the module
  is reusable across regions.
- **Missing `sensitive = true` on secrets** — passwords and tokens should
  always be marked sensitive.
- **`any` type in child modules** — loses type safety; prefer explicit
  `object({...})` types.