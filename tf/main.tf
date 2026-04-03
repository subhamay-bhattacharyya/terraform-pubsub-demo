# -- tf/main.tf (Root Module)
# ============================================================================
# Root Module — GCS Bucket Module Invocation
# ============================================================================

# ----------------------------------------------------------------------------
# Terraform configuration invoking the gcs-bucket module from GitHub
# ----------------------------------------------------------------------------
module "gcs_basic" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-google-gcs-bucket?ref=main"

  environment  = local._env_map[var.environment]
  project_id   = var.project_id
  project_code = var.project_code
  gcs_config   = local.gcs_basic
}
