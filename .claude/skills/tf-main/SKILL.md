---
name: tf-main
description: >
  Use this skill to create a Terraform main.tf file for GCP projects. Trigger
  when the user wants to: create or generate a main.tf; invoke a remote GitHub
  module for each service config; wire locals into module calls; or scaffold
  root module invocations. Also trigger when the user says "main.tf", "module
  invocation", "module call", "github module", or "root module" — even if they
  don't mention "main.tf" by name. ALWAYS trigger this skill when
  scaffold-terraform requests main.tf generation — do not generate main.tf
  without consulting this skill.
argument-hint: |
  $0 = service_name: GCP service name matching the locals and module
    (e.g. gcs_bucket, cloud_sql) — used to derive module label and local refs
  $1 = module_short_name: short module label used in module block names
    (e.g. gcs for gcs_bucket, sql for cloud_sql)
  $2 = github_org: GitHub org hosting the remote module
    (default: subhamay-bhattacharyya-tf)
  $3 = module_repo: GitHub repository name of the remote module
    (e.g. terraform-google-gcs-bucket)
  $4 = git_ref: git branch, tag, or SHA to pin the module source
    (e.g. feature/TFMOD-0001-initial-module-scaffold-f)
  $5 = config_keys: comma-separated config keys matching locals
    (default: basic — add basic_1, basic_2 etc. as needed)
---

# Terraform Main — GCP Skill

Creates `tf/main.tf`. **Always write this file immediately upon invocation —
do not wait for further input.**

## CRITICAL: Always Generate the File

Upon invocation, immediately create `tf/main.tf` using the template below.
Use `$ARGUMENTS` values, falling back to defaults where specified.

## Structure

One `module` block per config key in `$5` (e.g. `basic`, `basic_1`, `basic_2`).
Each block:
- Is named `<module_short_name>_<key>` (e.g. `gcs_basic`, `gcs_basic_1`)
- Sources from `github.com/<github_org>/<module_repo>?ref=<git_ref>`
- Passes `environment`, `project_id`, `project_code` from `var.*`
- Passes `<service_name>_config` from the corresponding named local
  `local.<service_name>_<key>`

## Template

```hcl
# -- tf/main.tf (Root Module)
# ============================================================================
# Root Module — $0 Module Invocation
# ============================================================================

# ----------------------------------------------------------------------------
# Terraform configuration invoking the $3 module from GitHub
# ----------------------------------------------------------------------------
module "$1_basic" {
  source = "github.com/$2/$3?ref=$4"

  environment  = local._env_map[var.environment]
  project_id   = var.project_id
  project_code = var.project_code
  $0_config    = local.$0_basic
}
# Repeat for each additional key in $5:
# module "$1_basic_1" {
#   source = "github.com/$2/$3?ref=$4"
#
#   environment  = local._env_map[var.environment]
#   project_id   = var.project_id
#   project_code = var.project_code
#   $0_config    = local.$0_basic_1
# }
```

## Concrete Example

For `$0 = gcs_bucket`, `$1 = gcs`, `$2 = subhamay-bhattacharyya-tf`,
`$3 = terraform-google-gcs-bucket`,
`$4 = feature/TFMOD-0001-initial-module-scaffold-f`,
`$5 = basic,basic_1,basic_2`:

```hcl
# -- tf/main.tf (Root Module)
# ============================================================================
# Root Module — GCS Bucket Module Invocation
# ============================================================================

# ----------------------------------------------------------------------------
# Terraform configuration invoking the gcs-bucket module from GitHub
# ----------------------------------------------------------------------------
module "gcs_basic" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-google-gcs-bucket?ref=feature/TFMOD-0001-initial-module-scaffold-f"

  environment  = local._env_map[var.environment]
  project_id   = var.project_id
  project_code = var.project_code
  gcs_config   = local.gcs_bucket_basic
}

module "gcs_basic_1" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-google-gcs-bucket?ref=feature/TFMOD-0001-initial-module-scaffold-f"

  environment  = local._env_map[var.environment]
  project_id   = var.project_id
  project_code = var.project_code
  gcs_config   = local.gcs_bucket_basic_1
}

module "gcs_basic_2" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-google-gcs-bucket?ref=feature/TFMOD-0001-initial-module-scaffold-f"

  environment  = local._env_map[var.environment]
  project_id   = var.project_id
  project_code = var.project_code
  gcs_config   = local.gcs_bucket_basic_2
}
```

## Rules

- File is ALWAYS `tf/main.tf` — never in any other location.
- Module block name is ALWAYS `<module_short_name>_<key>` — never `<service_name>_<key>`.
- `source` ALWAYS uses the full `github.com/<org>/<repo>?ref=<git_ref>` format.
- `environment` ALWAYS references `local._env_map[var.environment]` — never `var.environment` directly.
- `<service_name>_config` ALWAYS references `local.<service_name>_<key>` — never inline object literals.
- One module block per config key — generate all keys from `$5`, never collapse into a single block.
- Do NOT add `for_each` or `count` — each config key gets its own explicit module block.
- Do NOT skip or defer file creation — write `tf/main.tf` immediately.