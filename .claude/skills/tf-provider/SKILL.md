---
name: tf-provider
description: >
  Use this skill to create a Terraform provider configuration file
  (providers.tf) for GCP projects. Trigger when the user wants to: create or
  generate a providers.tf; configure the Google provider; set required provider
  versions; or add provider configuration to a Terraform project. Also trigger
  when the user says "providers.tf", "google provider", "provider config", or
  "required providers" — even if they don't mention "providers.tf" by name.
argument-hint: |
  $0 = google_provider_version: Google provider version (default: 7.25.0)
---

# Terraform Provider — GCP Skill

Creates `tf/providers.tf` with the Google provider configuration.

## Template

File is always created at `tf/providers.tf`.

```hcl
# -- tf/providers.tf (Platform Module)

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "$0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
}
```

## Rules

- File is always `tf/providers.tf` — never in any other location.
- `version` is always an exact pin (e.g. `7.25.0`) — never a range constraint.
- `credentials`, `project`, and `region` always reference `var.credentials_file`,
  `var.project_id`, and `var.region` respectively — never hardcoded values.
- Do not add `required_version` for Terraform itself here — that belongs in
  `backend.tf` or `versions.tf`.
- Do not add any providers other than `google` unless explicitly asked.