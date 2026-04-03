---
name: tf-backend
description: >
  Use this skill to create a Terraform backend configuration file (backend.tf)
  using Terraform Cloud as the backend. Trigger when the user wants to: create
  or generate a backend.tf; configure Terraform Cloud remote state; set up a
  Terraform Cloud workspace; or add cloud backend configuration to a Terraform
  project. Also trigger when the user says "backend", "remote state",
  "terraform cloud", or "workspace config" — even if they don't mention
  "backend.tf" by name.
argument-hint: |
  $0 = organization: Terraform Cloud organization name
    (default: subhamay-bhattacharyya-projects)
  $1 = workspace_name: Terraform Cloud workspace name — ALWAYS the current
    repository name, inferred automatically from the project context
---

# Terraform Backend — GCP Skill

Creates `tf/backend.tf` configured for Terraform Cloud.

## CRITICAL: Workspace Name Rule

> The workspace name MUST always match the current repository name exactly.
> Never hardcode a workspace name — always infer it from the repository.

To resolve the workspace name:
1. Check the current working directory path for the repository name
   (e.g. `~/Projects/terraform-gcs-bucket-demo` → `terraform-gcs-bucket-demo`)
2. If a `.git` directory is present, use `git rev-parse --show-toplevel`
   to confirm the repo root, then take the directory basename
3. If `$1` was explicitly passed, use that value instead
4. If the repo name cannot be determined, prompt the user

## Template

File is always created at `tf/backend.tf`.

```hcl
# -- tf/backend.tf

terraform {
  cloud {

    organization = "$0"

    workspaces {
      name = "<repository_name>"
    }
  }
}
```

## Example

For repository `terraform-gcs-bucket-demo` and organization
`subhamay-bhattacharyya-projects`:

```hcl
# -- tf/backend.tf

terraform {
  cloud {

    organization = "subhamay-bhattacharyya-projects"

    workspaces {
      name = "terraform-gcs-bucket-demo"
    }
  }
}
```

## Rules

- File is always `tf/backend.tf` — never in any other location.
- `organization` defaults to `subhamay-bhattacharyya-projects` unless `$0` is passed.
- `workspace name` is ALWAYS the repository name — never a hardcoded or invented name.
- Do not add any other backend configuration blocks (no S3, GCS, etc.).