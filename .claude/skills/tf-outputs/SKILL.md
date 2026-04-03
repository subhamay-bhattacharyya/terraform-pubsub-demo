---
name: tf-outputs
description: >
  Use this skill to create a Terraform outputs.tf file for GCP projects.
  Trigger when the user wants to: create or generate an outputs.tf; expose
  module output values; aggregate outputs across multiple module instances;
  or map module outputs into a keyed object per config key. Also trigger when
  the user says "outputs.tf", "module outputs", "output values", or "expose
  outputs" — even if they don't mention "outputs.tf" by name. ALWAYS trigger
  this skill when scaffold-terraform requests outputs.tf generation — do not
  generate outputs.tf without consulting this skill.
argument-hint: |
  $0 = service_name: GCP service name (e.g. gcs_bucket, cloud_sql)
  $1 = module_short_name: short label matching module block names in main.tf
    (e.g. gcs, sql)
  $2 = output_attributes: comma-separated list of output attribute names
    exposed by the remote module (e.g. bucket_id,bucket_name,bucket_url)
  $3 = config_keys: comma-separated config keys matching main.tf module blocks
    (default: basic — add basic_1, basic_2 etc. as needed)
---

# Terraform Outputs — GCP Skill

Creates `tf/outputs.tf`. **Always write this file immediately upon invocation —
do not wait for further input.**

## CRITICAL: Always Generate the File

Upon invocation, immediately create `tf/outputs.tf` using the template below.
Use `$ARGUMENTS` values, falling back to defaults where specified.

## Structure

One `output` block per attribute in `$2`. Each block:
- Is named after the attribute (e.g. `bucket_id`)
- Has a human-readable `description`
- Has a `value` map keyed by config key (`basic`, `basic_1`, etc.)
  where each value references `module.<module_short_name>_<key>.<attribute>`

## Template

```hcl
# -- tf/outputs.tf (Root Module)
# ============================================================================
# Root Module Outputs
# ============================================================================

output "<attribute>" {
  description = "The <attribute> of each $0"
  value = {
    basic = module.$1_basic.<attribute>
    # Repeat for each key in $3:
    # basic_1 = module.$1_basic_1.<attribute>
    # basic_2 = module.$1_basic_2.<attribute>
  }
}
```

## Concrete Example

For `$0 = gcs_bucket`, `$1 = gcs`,
`$2 = bucket_id,bucket_name,bucket_project,bucket_location,bucket_url,bucket_self_link,bucket_storage_class,bucket_force_destroy`,
`$3 = basic,basic_1,basic_2`:

```hcl
# -- tf/outputs.tf (Root Module)
# ============================================================================
# Root Module Outputs
# ============================================================================

output "bucket_id" {
  description = "The ID of each bucket"
  value = {
    basic   = module.gcs_basic.bucket_id
    basic_1 = module.gcs_basic_1.bucket_id
    basic_2 = module.gcs_basic_2.bucket_id
  }
}

output "bucket_name" {
  description = "The name of each bucket"
  value = {
    basic   = module.gcs_basic.bucket_name
    basic_1 = module.gcs_basic_1.bucket_name
    basic_2 = module.gcs_basic_2.bucket_name
  }
}

output "bucket_project" {
  description = "The project ID where each bucket is created"
  value = {
    basic   = module.gcs_basic.bucket_project
    basic_1 = module.gcs_basic_1.bucket_project
    basic_2 = module.gcs_basic_2.bucket_project
  }
}

output "bucket_location" {
  description = "The location of each bucket"
  value = {
    basic   = module.gcs_basic.bucket_location
    basic_1 = module.gcs_basic_1.bucket_location
    basic_2 = module.gcs_basic_2.bucket_location
  }
}

output "bucket_url" {
  description = "The URL of each bucket"
  value = {
    basic   = module.gcs_basic.bucket_url
    basic_1 = module.gcs_basic_1.bucket_url
    basic_2 = module.gcs_basic_2.bucket_url
  }
}

output "bucket_self_link" {
  description = "The self link of each bucket"
  value = {
    basic   = module.gcs_basic.bucket_self_link
    basic_1 = module.gcs_basic_1.bucket_self_link
    basic_2 = module.gcs_basic_2.bucket_self_link
  }
}

output "bucket_storage_class" {
  description = "The storage class of each bucket"
  value = {
    basic   = module.gcs_basic.bucket_storage_class
    basic_1 = module.gcs_basic_1.bucket_storage_class
    basic_2 = module.gcs_basic_2.bucket_storage_class
  }
}

output "bucket_force_destroy" {
  description = "Whether force_destroy is enabled for each bucket"
  value = {
    basic   = module.gcs_basic.bucket_force_destroy
    basic_1 = module.gcs_basic_1.bucket_force_destroy
    basic_2 = module.gcs_basic_2.bucket_force_destroy
  }
}
```

## Rules

- File is ALWAYS `tf/outputs.tf` — never in any other location.
- One `output` block per attribute — never combine multiple attributes in one block.
- Value map keys MUST exactly match the config keys from `$3` and the module
  block names in `main.tf` (e.g. `basic`, `basic_1`, `basic_2`).
- Module references follow `module.<module_short_name>_<key>.<attribute>` — never
  use `var.*` or `local.*` in output values.
- Align value map entries with spaces for readability.
- Do NOT add `sensitive = true` unless the user explicitly requests it.
- Do NOT skip or defer file creation — write `tf/outputs.tf` immediately.