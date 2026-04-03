# -- tf/variables.tf

# -- The two variables environment and project_code are must for all Terraform
# -- configurations. They are used for naming resources and defining the
# -- environment in which the infrastructure will be deployed.

variable "environment" {
  description = "Environment name (devl, test, prod)"
  type        = string
  default     = "devl"

  validation {
    condition     = contains(["devl", "test", "prod"], var.environment)
    error_message = "Environment must be devl, test, or prod."
  }
}

variable "project_code" {
  description = "Project code prefix for resource naming (e.g., gcsdemo)"
  type        = string
  default     = "gcsdemo"
}

# Configuration File Paths
# ============================================================================

variable "gcs_config_path" {
  description = "Map of config keys to GCS config JSON file paths"
  type        = map(string)
  default = {
    basic = "gcs_config.json"
  }
}

variable "credentials_file" {
  description = "Path to the GCP service account credentials JSON file"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID in which resources will be created."
  type        = string
}

variable "region" {
  description = "GCP region for provider configuration (e.g., us-central1)"
  type        = string
}
