---
name: scaffold-terraform
description: >
  Use this skill to scaffold a complete Terraform project structure for GCP.
  Trigger when the user wants to: create a new Terraform project from scratch;
  generate the standard set of config files (variables.tf, locals.tf,
  outputs.tf, main.tf, versions.tf); set up the tf/ directory layout; or
  bootstrap a new GCP service module. Also trigger when the user says "scaffold",
  "bootstrap", "create terraform project", "set up terraform", or "generate
  terraform files" — even if they don't mention specific file names.
disable-model-invocation: false
argument-hint: |
  $0 = service_name: GCP service being configured — sets the <service_name>_config
    variable name (e.g. gcs_bucket, cloud_sql, pubsub_topic, cloud_run_service)
  $1 = project_code: short project prefix for resource naming (e.g. snw, lkh)
  $2 = region: GCP region (default: us-central1)
  $3 = project_id: GCP project ID (required)
  $4 = google_provider_version: Google provider version constraint (default: = 7.25.0)
---

# Scaffold Terraform — GCP Skill

Scaffolds a complete GCP Terraform project under the `tf/` directory.

## CRITICAL: tfvars File Naming and Location

> These rules are non-negotiable. Do not deviate.

- File name is ALWAYS `auto.terraform.tfvars.json` — NEVER `devl.terraform.tfvars.json`,
  `test.terraform.tfvars.json`, or `prod.terraform.tfvars.json`
- Files MUST be created in separate subdirectories, one per environment:
  - `tf/environments/devl/auto.terraform.tfvars.json`
  - `tf/environments/test/auto.terraform.tfvars.json`
  - `tf/environments/prod/auto.terraform.tfvars.json`
- The parent directory is `environments` (plural) — NEVER `environment` (singular)

## Workflow

1. Resolve all values from `$ARGUMENTS`, falling back to defaults where specified.
   Prompt the user for any required argument (`$0`, `$1`, `$3`) not supplied.
2. Read `references/template-spec.md` for file templates and rules.
3. Generate `tf/variables.tf` and `.tfvars` files using the **tf-variables** skill,
   passing `$0` (service_name), `$1` (project_code), `$2` (region), `$3` (project_id).
4. Generate `tf/backend.tf` using the **tf-backend** skill, passing `$0` (organization).
   The skill will infer the workspace name from the current repository name automatically.
5. Generate `tf/providers.tf` using the **tf-provider** skill, passing `$4` (google_provider_version).
6. **Stop after step 5 unless the user explicitly asks for more.** Only generate
   `locals.tf`, `outputs.tf`, `main.tf` when asked — either individually
   ("generate locals.tf") or all at once ("generate all files").
   When generating `locals.tf`, use the **tf-locals** skill, passing
   `$0` (service_name) and the config keys from `var.<service_name>_config_path`.
