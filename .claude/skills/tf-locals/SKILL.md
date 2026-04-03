---
name: tf-locals
description: >
  Use this skill to create a Terraform locals.tf file for GCP projects.
  Trigger when the user wants to: create or generate a locals.tf; decode JSON
  config files into local values; build object maps from raw JSON inputs; map
  input JSON fields to a remote module's variable schema; or construct
  <service_name>_config locals from jsondecode. Also trigger when the user says
  "locals.tf", "jsondecode", "local values", "config map", or "object map" —
  even if they don't mention "locals.tf" by name. ALWAYS trigger this skill
  when scaffold-terraform requests locals.tf generation — do not generate
  locals.tf without consulting this skill.
argument-hint: |
  $0 = service_name: GCP service name — drives _raw_<service_name>_* local
    names and the <service_name>_config object map (e.g. gcs_bucket, cloud_sql)
  $1 = config_keys: comma-separated config file keys from service_config_path
    variable (default: basic — add basic_1, basic_2 etc. as needed)
---

# Terraform Locals — GCP Skill

Creates `tf/locals.tf`. **Always write this file immediately upon invocation —
do not wait for further input.**

## CRITICAL: Always Generate the File

Upon invocation, immediately create `tf/locals.tf` using the template below.
Do not ask clarifying questions first — use `$0` and `$1` from `$ARGUMENTS`,
falling back to defaults (`basic` for config keys) if not supplied.

## Structure

The file has two sections:

1. **Raw JSON decode block** — one `jsondecode(file(...))` entry per config key
   in `var.<service_name>_config_path`, named `_raw_<service_name>_<key>`
2. **Named local variables block** — one named local per config key, e.g.
   `<service_name>_<key>`, using `try()` for optional fields with sensible
   defaults, `merge()` for labels, and nested blocks for objects like `versioning`

## Key Patterns

### Required fields
Use direct access — no `try()`:
```hcl
base_name = local._raw_$0_basic.base_name
```

### Optional fields with defaults
Always use `try()` with a sensible default:
```hcl
location      = try(local._raw_$0_basic.location, "US")
storage_class = try(local._raw_$0_basic.storage_class, "STANDARD")
force_destroy = try(local._raw_$0_basic.force_destroy, false)
kms_key_name  = try(local._raw_$0_basic.kms_key_name, null)
```

### Labels
Always merge JSON labels with mandatory Terraform-managed labels:
```hcl
labels = merge(
  try(local._raw_$0_basic.labels, {}),
  {
    environment = var.environment
    managed_by  = "terraform"
  }
)
```

### Nested objects (e.g. versioning)
Use a nested block with `try()`:
```hcl
versioning = {
  enabled = try(local._raw_$0_basic.versioning.enabled, true)
}
```

## Template

```hcl
# -- tf/locals.tf

locals {

  # ---------------------------------------------------------------------------
  # Raw JSON decode — one entry per key in var.$0_config_path
  # ---------------------------------------------------------------------------

  _raw_$0_basic = jsondecode(file("${path.module}/../input-jsons/${var.environment}/${var.$0_config_path.basic}"))
  # Repeat for each additional key in $1:
  # _raw_$0_basic_1 = jsondecode(file("${path.module}/../input-jsons/${var.environment}/${var.$0_config_path.basic_1}"))

  # ---------------------------------------------------------------------------
  # Named locals — one per config key, fields use try() with defaults
  # ---------------------------------------------------------------------------

  $0_basic = {
    base_name     = local._raw_$0_basic.base_name
    location      = try(local._raw_$0_basic.location, "US")
    storage_class = try(local._raw_$0_basic.storage_class, "STANDARD")
    force_destroy = try(local._raw_$0_basic.force_destroy, false)
    kms_key_name  = try(local._raw_$0_basic.kms_key_name, null)
    labels = merge(
      try(local._raw_$0_basic.labels, {}),
      {
        environment = var.environment
        managed_by  = "terraform"
      }
    )
    versioning = {
      enabled = try(local._raw_$0_basic.versioning.enabled, true)
    }
  }
  # Repeat for each additional key in $1:
  # $0_basic_1 = {
  #   base_name     = local._raw_$0_basic_1.base_name
  #   location      = try(local._raw_$0_basic_1.location, "US")
  #   ...
  # }

}
```

## Concrete Example

For `$0 = gcs_bucket`, `$1 = basic,basic_1` — write this file exactly:

```hcl
# -- tf/locals.tf

locals {

  # ---------------------------------------------------------------------------
  # Raw JSON decode
  # ---------------------------------------------------------------------------

  _raw_gcs_bucket_basic   = jsondecode(file("${path.module}/../input-jsons/${var.environment}/${var.gcs_config_path.basic}"))
  _raw_gcs_bucket_basic_1 = jsondecode(file("${path.module}/../input-jsons/${var.environment}/${var.gcs_config_path.basic_1}"))

  # ---------------------------------------------------------------------------
  # Named locals matching remote module's gcs_bucket_config schema
  # ---------------------------------------------------------------------------

  gcs_bucket_basic = {
    base_name     = local._raw_gcs_bucket_basic.base_name
    location      = try(local._raw_gcs_bucket_basic.location, "US")
    storage_class = try(local._raw_gcs_bucket_basic.storage_class, "STANDARD")
    force_destroy = try(local._raw_gcs_bucket_basic.force_destroy, false)
    kms_key_name  = try(local._raw_gcs_bucket_basic.kms_key_name, null)
    labels = merge(
      try(local._raw_gcs_bucket_basic.labels, {}),
      {
        environment = var.environment
        managed_by  = "terraform"
      }
    )
    versioning = {
      enabled = try(local._raw_gcs_bucket_basic.versioning.enabled, true)
    }
  }

  gcs_bucket_basic_1 = {
    base_name     = local._raw_gcs_bucket_basic_1.base_name
    location      = try(local._raw_gcs_bucket_basic_1.location, "US")
    storage_class = try(local._raw_gcs_bucket_basic_1.storage_class, "STANDARD")
    force_destroy = try(local._raw_gcs_bucket_basic_1.force_destroy, false)
    kms_key_name  = try(local._raw_gcs_bucket_basic_1.kms_key_name, null)
    labels = merge(
      try(local._raw_gcs_bucket_basic_1.labels, {}),
      {
        environment = var.environment
        managed_by  = "terraform"
      }
    )
    versioning = {
      enabled = try(local._raw_gcs_bucket_basic_1.versioning.enabled, true)
    }
  }

}
```

## Rules

- File is ALWAYS `tf/locals.tf` — never in any other location.
- Raw local names are ALWAYS `_raw_<service_name>_<key>` (underscore-prefixed).
- Named local variables are ALWAYS `<service_name>_<key>` (no underscore prefix).
- The `jsondecode` path ALWAYS uses `${path.module}/../input-jsons/${var.environment}/`
  — NEVER hardcode the environment name.
- Required fields use direct access; optional fields ALWAYS use `try()` with a default.
- Labels ALWAYS use `merge()` — JSON labels first, then mandatory managed labels.
- Nested objects (e.g. `versioning`) use a block with `try()` on each inner field.
- Do NOT add `name_prefix` or `common_labels` locals here.
- Do NOT skip or defer file creation — write `tf/locals.tf` immediately.