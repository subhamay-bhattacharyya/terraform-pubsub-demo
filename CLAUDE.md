# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this module does

This is a **Terraform IaC Configuration** that creates and manages one or more `google_storage_bucket` resource on GCP. The entire public interface is one input variable (`gcs_config`) and eight outputs (id, name, project, location, url, self_link, storage_class, force_destroy). 

## Common commands

```bash
# Format check (must pass before commit)
cd tf && terraform fmt -recursive
cd tf && terraform init -upgrade
cd tf && terraform plan
cd tf && terraform apply

# Validate root module
terraform init -backend=false && terraform validate

# Validate the example
cd examples/bucket/basic && terraform init -backend=false && terraform validate

# Run Terratest integration test (requires GCP auth + GOOGLE_CLOUD_PROJECT env var)
cd test && go test -v -timeout 30m -run TestGCSBucketBasic ./gcs_bucket_basic_test.go ./helpers_test.go

# Install local dev tools (Linux/devcontainer only)
bash install-tools.sh
bash install-tools.sh --tools=terraform,tflint,trivy  # install subset
bash install-tools.sh --dry-run                        # preview only

# Run pre-commit hooks
pre-commit run --all-files
```

## Architecture

```text
.                      # Root module — the publishable Terraform module
## Folder Structure
```text
tf/
├── environment/
│   ├── devl.terraform.tfvars.json  # Variable values for the development environment
│   ├── test.terraform.tfvars.json  # Variable values for the test environment
│   └── prod.terraform.tfvars.json  # Variable values for the production environment
├── backend.tf                      # Configures the Terraform remote backend (e.g., GCS bucket) where the state file is stored and locked
├── data.tf                         # Defines data sources used to fetch existing remote resources or external information (e.g., existing GCP project, IAM policies)
├── locals.tf                       # Declares local values used to simplify expressions, avoid repetition, and centralise computed or derived values across the configuration
├── main.tf                         # Core resource definitions — the primary entry point where GCS bucket and associated resources are provisioned
├── outputs.tf                      # Defines output values exposed after `terraform apply`, such as bucket name, URL, or self-link
├── providers.tf                    # Configures the required Terraform providers (e.g., `hashicorp/google`) including version constraints and authentication settings
├── terraform.auto.tfvars.json      # Supplies actual values for the declared variables — automatically loaded by Terraform, excluded from version control
└── variables.tf                    # Declares all input variables with types, descriptions, and default values used across the configuration
```

## Key Conventions

- Terraform files use `tf/` directory with standard layout (`main.tf,` `variables.tf`, `outputs.tf`, `data.tf`, `providers.tf,` `backend.tf`, `environment/[devl/test/prod].terraform.tfvars.json`)
- GitHub Actions uses OIDC — no stored AWS access keys
- All infrastructure changes go through Terraform — never modify AWS resources manually
- Site content changes deploy automatically via GitHub Actions on push to main
- This Terraform module only sccept one input of object type

The module uses a single structured `gcs_config` object rather than flat variables. All validation (naming rules, storage class enum, project ID format, public access prevention values) lives in `variables.tf`.

## CI pipeline (`.github/workflows/ci.yaml`)

Runs on pushes/PRs to `main`, `feature/**`, `bug/**` when `.tf`, `examples/**`, or `test/**` files change:

1. **terraform-validate** — `fmt -check`, `init`, `validate` on the root module
2. **examples-validate** — `init` + `validate` on `examples/bucket/basic` (needs step 1)
3. **terratest** — real GCP integration test via Workload Identity Federation (needs step 2); requires `GCP_PROJECT_ID`, `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT` repo vars
4. **generate-changelog** — runs `git-cliff` on non-main branches (needs step 2)
5. **semantic-release** — runs only on `main` after steps 2 and 3; uses Conventional Commits to auto-version

## Commit message convention

Follows **Conventional Commits** — semantic-release uses this to determine the next version:

- `feat:` → minor bump
- `fix:` → patch bump
- `chore:`, `docs:`, `refactor:`, etc. → no release
- Breaking changes via `BREAKING CHANGE:` footer → major bump

## Known inconsistencies (leftover from template)

- `README.md` describes a GCP project-hierarchy module — it is stale and does not reflect this module.
- `test/helpers_test.go` contains AWS S3 helpers; `test/go.mod` references `terraform-aws-s3`. These are unused by the GCS test and should be replaced with GCS-specific helpers when adding new tests.
- `install-tools.sh` includes AWS CLI installation; not needed for a GCP-only module.
