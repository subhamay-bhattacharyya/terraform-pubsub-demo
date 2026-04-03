# -- tf/outputs.tf (Root Module)
# ============================================================================
# Root Module Outputs
# ============================================================================

output "bucket_id" {
  description = "The ID of each bucket"
  value = {
    basic = module.gcs_basic.bucket_id
  }
}

output "bucket_name" {
  description = "The name of each bucket"
  value = {
    basic = module.gcs_basic.bucket_name
  }
}

output "bucket_project" {
  description = "The project ID where each bucket is created"
  value = {
    basic = module.gcs_basic.bucket_project
  }
}

output "bucket_location" {
  description = "The location of each bucket"
  value = {
    basic = module.gcs_basic.bucket_location
  }
}

output "bucket_url" {
  description = "The URL of each bucket"
  value = {
    basic = module.gcs_basic.bucket_url
  }
}

output "bucket_self_link" {
  description = "The self link of each bucket"
  value = {
    basic = module.gcs_basic.bucket_self_link
  }
}

output "bucket_storage_class" {
  description = "The storage class of each bucket"
  value = {
    basic = module.gcs_basic.bucket_storage_class
  }
}

output "bucket_force_destroy" {
  description = "Whether force_destroy is enabled for each bucket"
  value = {
    basic = module.gcs_basic.bucket_force_destroy
  }
}
