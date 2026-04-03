# -- tf/locals.tf

locals {

  # ---------------------------------------------------------------------------
  # Environment short-name map
  # ---------------------------------------------------------------------------

  _env_map = {
    devl = "devl"
    test = "test"
    prod = "prod"
  }

  # ---------------------------------------------------------------------------
  # Raw JSON decode — one entry per key in var.gcs_config_path
  # ---------------------------------------------------------------------------

  _raw_gcs_basic = jsondecode(file("${path.module}/../input-jsons/${var.environment}/${var.gcs_config_path.basic}"))

  # ---------------------------------------------------------------------------
  # Named locals — fields use try() with defaults
  # ---------------------------------------------------------------------------

  gcs_basic = {
    name                        = local._raw_gcs_basic.name
    location                    = try(local._raw_gcs_basic.location, "US")
    storage_class               = try(local._raw_gcs_basic.storage_class, "STANDARD")
    force_destroy               = try(local._raw_gcs_basic.force_destroy, false)
    uniform_bucket_level_access = try(local._raw_gcs_basic.uniform_bucket_level_access, true)
    public_access_prevention    = try(local._raw_gcs_basic.public_access_prevention, "enforced")
    versioning_enabled          = try(local._raw_gcs_basic.versioning_enabled, false)
    labels = merge(
      try(local._raw_gcs_basic.labels, {}),
      {
        environment = var.environment
        managed_by  = "terraform"
      }
    )
  }

}
