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
  $5 = module_short_name: short label for module block names in main.tf (e.g. gcs, sql)
  $6 = module_repo: GitHub repository name of the remote module
    (e.g. terraform-google-gcs-bucket)
  $7 = git_ref: git branch, tag or SHA to pin the remote module source
  $8 = config_keys: comma-separated config keys (default: basic)
  $9 = output_attributes: comma-separated output attribute names exposed by
    the remote module (e.g. bucket_id,bucket_name,bucket_url,bucket_self_link)
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
3. Generate `tf/providers.tf` using the **tf-provider** skill, passing `$4` (google_provider_version).
   Do NOT skip this step — providers.tf is always part of the scaffold.
4. Generate `tf/backend.tf` using the **tf-backend** skill, passing `$0` (organization).
   The skill will infer the workspace name from the current repository name automatically.
   Do NOT skip this step — backend.tf is always part of the scaffold.
5. Generate `tf/variables.tf` and `.tfvars` files using the **tf-variables** skill,
   passing `$0` (service_name), `$1` (project_code), `$2` (region), `$3` (project_id).
   Do NOT skip this step — variables.tf and tfvars are always part of the scaffold.
6. Generate `tf/locals.tf` using the **tf-locals** skill, passing `$0` (service_name)
   and the config keys from `var.<service_name>_config_path` (e.g. `basic,basic_1`).
   Do NOT skip this step — locals.tf is always part of the scaffold.
7. Generate `tf/main.tf` using the **tf-main** skill, passing `$0` (service_name),
   `$5` (module_short_name), `subhamay-bhattacharyya-tf` (github_org), `$6` (module_repo),
   `$7` (git_ref), and `$8` (config_keys).
   Do NOT skip this step — main.tf is always part of the scaffold.
8. Generate `tf/outputs.tf` using the **tf-outputs** skill, passing `$0` (service_name),
   `$5` (module_short_name), `$9` (output_attributes), and `$8` (config_keys).
   Do NOT skip this step — outputs.tf is always part of the scaffold.
9. Invoke the **update-contributing** skill to update `CONTRIBUTING.md`.
   Pass `$0` (github_org, default: subhamay-bhattacharyya-gha). The skill
   infers the repository name automatically from the current repo.
   Do NOT skip, defer, or summarise this step — the file MUST be written.
10. Invoke the **github-readme** skill to generate or update `README.md`.
    Pass `$0` (service_name) and the inferred repository name.
    Do NOT skip, defer, or summarise this step — README.md MUST be written.
11. Generate or update `package.json` in the repository root. Infer the
    repository name from the current repo. Write the file with the following
    rules — do NOT skip or defer:
    - `name`: repository name (e.g. `terraform-google-service-demo`)
    - `version`: `"1.0.0"`
    - `description`: `"Terraform module for provisioning a <service_name> resource on GCP."` — replace `<service_name>` with a human-readable form of `$0`
    - `scripts`:
      - `"lint": "pre-commit run --all-files"`
      - `"tf:fmt": "cd tf && terraform fmt -recursive"`
      - `"tf:validate": "cd tf && terraform init -backend=false && terraform validate"`
      - `"tf:plan:devl": "cd tf && terraform plan -var-file=environments/devl/auto.terraform.tfvars.json"`
      - `"tf:plan:test": "cd tf && terraform plan -var-file=environments/test/auto.terraform.tfvars.json"`
      - `"tf:plan:prod": "cd tf && terraform plan -var-file=environments/prod/auto.terraform.tfvars.json"`
    - `repository`:
      - `"type": "git"`
      - `"url": "https://github.com/subhamay-bhattacharyya-gha/<repository_name>"` — ALWAYS use `subhamay-bhattacharyya-gha` org, NEVER `subhamay-bhattacharyya-tf`
    - `keywords`: `["terraform", "gcp", "<service_keyword>", "iac"]` — derive `<service_keyword>` from `$0` (e.g. `gcs` → `"google-cloud-storage"`)
    - `license`: `"MIT"`