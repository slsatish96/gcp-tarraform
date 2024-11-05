# Description: Input variables of main.tf


# project_id is a mandatory variable from users
variable "project_id" {
  type        = string
  description = "The GCP project where the cluster will be created in."
}

# credential_file is a mandatory variable from users
variable "credential_file" {
  type        = string
  description = "The JSON credential file of a service account with project editor role."
}

variable "region" {
  type        = string
  description = "The region where the resources will be allocated in."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "The zone under the region where the resources will be allocated in."
  default     = "us-central1-a"
}

variable "network_storage" {
  type = list(
    object(
      {
        server_ip     = string,
        remote_mount  = string,
        local_mount   = string,
        fs_type       = string,
        mount_options = string
      }
    )
  )
  description = " An array of network attached storage mounts to be configured on all instances."
  default     = []
}

