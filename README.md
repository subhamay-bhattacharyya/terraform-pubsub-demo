# terraform-google-service-demo

![Release](https://github.com/subhamay-bhattacharyya-tf/terraform-google-service-demo/actions/workflows/ci.yaml/badge.svg)&nbsp;![GCP](https://img.shields.io/badge/GCP-4285F4?logo=googlecloud&logoColor=white)&nbsp;![Commit Activity](https://img.shields.io/github/commit-activity/t/subhamay-bhattacharyya-tf/terraform-google-service-demo)&nbsp;![Last Commit](https://img.shields.io/github/last-commit/subhamay-bhattacharyya-tf/terraform-google-service-demo)&nbsp;![Release Date](https://img.shields.io/github/release-date/subhamay-bhattacharyya-tf/terraform-google-service-demo)&nbsp;![Repo Size](https://img.shields.io/github/repo-size/subhamay-bhattacharyya-tf/terraform-google-service-demo)&nbsp;![File Count](https://img.shields.io/github/directory-file-count/subhamay-bhattacharyya-tf/terraform-google-service-demo)&nbsp;![Issues](https://img.shields.io/github/issues/subhamay-bhattacharyya-tf/terraform-google-service-demo)&nbsp;![Top Language](https://img.shields.io/github/languages/top/subhamay-bhattacharyya-tf/terraform-google-service-demo)&nbsp;![Built with Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-623CE4?logo=anthropic&logoColor=white)&nbsp;![Custom Endpoint](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bsubhamay/476e6e7583432e960e6de16d5223e6a3/raw/terraform-google-service-demo.json?)&nbsp;![Terraform Version](https://img.shields.io/badge/terraform-%3E%3D1.3-blue)&nbsp;![Provider Version](https://img.shields.io/badge/google-%3D7.25.0-blue)

Terraform root module that provisions and manages a **Google Cloud Storage (GCS) bucket** on GCP.

---

## Overview

This repository is a Terraform root module that provisions a GCS bucket on GCP by invoking the remote `terraform-google-gcs-bucket` module from GitHub. Configuration is supplied per-environment via JSON input files (`input-jsons/<env>/gcs_config.json`) and referenced through the `gcs_config_path` variable. The module supports three environments — `devl`, `test`, and `prod` — each with its own `tf/environments/<env>/auto.terraform.tfvars.json` file. Remote state is managed via Terraform Cloud (HCP).

---

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3.0 |
| google | = 7.25.0 |

**Additional prerequisites:**
- GCP service account credentials JSON at `tf/sa-key/sa-key.json`
- Terraform Cloud organisation `subhamay-bhattacharyya-projects` with workspace `terraform-google-service-demo`
- GCP project `prj-17-cloud-storage-16748` with Storage API enabled

---

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `environment` | `string` | No | `"devl"` | Environment name — `devl`, `test`, or `prod`. |
| `project_code` | `string` | No | `"gcsdemo"` | Short project prefix used in resource naming. |
| `gcs_config_path` | `map(string)` | No | `{ basic = "gcs_config.json" }` | Map of config keys to GCS config JSON filenames. |
| `credentials_file` | `string` | Yes | — | Path to the GCP service account credentials JSON file. |
| `project_id` | `string` | Yes | — | GCP project ID in which resources will be created. |
| `region` | `string` | Yes | — | GCP region for provider configuration (e.g. `us-central1`). |

### `gcs_config.json` fields

| Field | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Globally unique bucket name. |
| `location` | `string` | `"US"` | Bucket location (region or multi-region). |
| `storage_class` | `string` | `"STANDARD"` | `STANDARD`, `NEARLINE`, `COLDLINE`, or `ARCHIVE`. |
| `force_destroy` | `bool` | `false` | Delete non-empty bucket on `terraform destroy`. |
| `uniform_bucket_level_access` | `bool` | `true` | Enable uniform bucket-level access (IAM-only). |
| `public_access_prevention` | `string` | `"enforced"` | `"enforced"` or `"inherited"`. |
| `versioning_enabled` | `bool` | `false` | Enable object versioning. |
| `labels` | `map(string)` | `{}` | Labels applied to the bucket. |

---

## Outputs

| Name | Description |
|---|---|
| `bucket_id` | Bucket ID. |
| `bucket_name` | Bucket name. |
| `bucket_project` | GCP project containing the bucket. |
| `bucket_location` | Bucket location. |
| `bucket_url` | `gs://` URL. |
| `bucket_self_link` | Bucket self-link URI. |
| `bucket_storage_class` | Storage class. |
| `bucket_force_destroy` | Whether force-destroy is enabled. |

---

## Environment tfvars

| File | Environment |
|---|---|
| `tf/environments/devl/auto.terraform.tfvars.json` | Development |
| `tf/environments/test/auto.terraform.tfvars.json` | Test |
| `tf/environments/prod/auto.terraform.tfvars.json` | Production |

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for full guidelines.

```bash
git clone git@github.com:subhamay-bhattacharyya-tf/terraform-google-service-demo.git
cd terraform-google-service-demo
cd tf && terraform fmt -recursive && terraform init -backend=false && terraform validate
```

1. Fork the repository and create a feature branch (`git checkout -b feat/my-change`)
2. Run `terraform fmt` and `terraform validate`
3. Open a pull request against `main` with a clear description of changes

---

## CI / Workload Identity Federation Setup

The CI workflow authenticates to GCP via [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation). If the job fails with `Permission 'iam.serviceAccounts.getAccessToken' denied`, grant the WIF pool principal the required IAM binding:

```bash
gcloud iam service-accounts add-iam-policy-binding \
    "<service-account-email>" \
    --project="prj-17-cloud-storage-16748" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/<project-number>/locations/global/workloadIdentityPools/<pool-name>/attribute.repository/subhamay-bhattacharyya-tf/terraform-google-service-demo"
```

The repository variables required by the CI workflow are:

| Variable | Description |
|---|---|
| `TF_LINT_VER` | TFLint version to install |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full WIF provider resource name |
| `GCP_SERVICE_ACCOUNT` | Service account email to impersonate |

---

## License

[MIT](LICENSE)
