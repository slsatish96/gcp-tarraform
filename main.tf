# Description: terraform scripts to create a cluster on Google Cloud Platform


terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.37.0"
    }
  }
}

provider "google" {
  credentials = file(var.credential_file)
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# hard-coded variables
locals {
  cluster_name                  = "gcp-cluster"
  disable_login_public_ips      = true
  disable_controller_public_ips = true
  disable_compute_public_ips    = true
  partitions = [
    {
      name                 = "debug-cpu",
      machine_type         = "c2-standard-4",
      max_node_count       = 2,
      zone                 = var.zone,
      compute_disk_type    = "pd-ssd",
      compute_disk_size_gb = 30,
      compute_labels       = {},
      cpu_platform         = "Intel Cascade Lake",
      gpu_count            = 0,
      gpu_type             = null,
      network_storage      = [],
      preemptible_bursting = true,
      vpc_subnet           = null,
      static_node_count    = 0
    },
    {
      name                 = "debug-gpu",
      machine_type         = "n1-standard-4",
      max_node_count       = 1,
      zone                 = var.zone,
      compute_disk_type    = "pd-ssd",
      compute_disk_size_gb = 30,
      compute_labels       = {},
      cpu_platform         = null,
      gpu_count            = 1,
      gpu_type             = "nvidia-tesla-v100",
      network_storage      = [],
      preemptible_bursting = true,
      vpc_subnet           = null,
      static_node_count    = 1
    },
  ]
  ompi_version = "v4.0.x"
}

module "slurm_cluster_network" {
  source = "github.com/SchedMD/slurm-gcp//tf/modules/network"

  cluster_name                  = local.cluster_name
  disable_login_public_ips      = local.disable_login_public_ips
  disable_controller_public_ips = local.disable_controller_public_ips
  disable_compute_public_ips    = local.disable_compute_public_ips
  network_name                  = null
  partitions                    = local.partitions
  private_ip_google_access      = true
  project                       = var.project_id
  region                        = var.region
  shared_vpc_host_project       = null
  subnetwork_name               = null
}

module "slurm_cluster_controller" {
  source = "github.com/SchedMD/slurm-gcp//tf/modules/controller"

  boot_disk_size = 100
  boot_disk_type = "pd-ssd"
  cloudsql       = null
  cluster_name   = local.cluster_name
  compute_node_scopes = [
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/logging.write"
  ]
  compute_node_service_account  = "default"
  disable_compute_public_ips    = local.disable_compute_public_ips
  disable_controller_public_ips = local.disable_controller_public_ips
  labels                        = {}
  login_network_storage         = []
  login_node_count              = 1
  machine_type                  = "n1-standard-2"
  munge_key                     = null
  network_storage               = var.network_storage
  ompi_version                  = local.ompi_version
  partitions                    = local.partitions
  project                       = var.project_id
  region                        = var.region
  secondary_disk                = false
  secondary_disk_size           = 100
  secondary_disk_type           = "pd-ssd"
  scopes                        = ["https://www.googleapis.com/auth/cloud-platform"]
  service_account               = "default"
  shared_vpc_host_project       = null
  slurm_version                 = "19.05-latest"
  subnet_depend                 = module.slurm_cluster_network.subnet_depend
  subnetwork_name               = null
  suspend_time                  = 300
  zone                          = var.zone
}

module "slurm_cluster_login" {
  source = "github.com/SchedMD/slurm-gcp//tf/modules/login"

  boot_disk_size            = 20
  boot_disk_type            = "pd-standard"
  cluster_name              = local.cluster_name
  controller_name           = module.slurm_cluster_controller.controller_node_name
  controller_secondary_disk = false
  disable_login_public_ips  = local.disable_login_public_ips
  labels                    = {}
  login_network_storage     = []
  machine_type              = "n1-standard-2"
  munge_key                 = null
  network_storage           = var.network_storage
  node_count                = 1
  ompi_version              = local.ompi_version
  region                    = var.region
  scopes = [
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/logging.write"
  ]
  service_account         = "default"
  shared_vpc_host_project = null
  subnet_depend           = module.slurm_cluster_network.subnet_depend
  subnetwork_name         = null
  zone                    = var.zone
}

module "slurm_cluster_compute" {
  source = "github.com/SchedMD/slurm-gcp//tf/modules/compute"

  compute_image_disk_size_gb = 20
  compute_image_disk_type    = "pd-ssd"
  compute_image_labels       = {}
  compute_image_machine_type = "n1-standard-2"
  controller_name            = module.slurm_cluster_controller.controller_node_name
  controller_secondary_disk  = 0
  cluster_name               = local.cluster_name
  disable_compute_public_ips = local.disable_compute_public_ips
  network_storage            = var.network_storage
  ompi_version               = local.ompi_version
  partitions                 = local.partitions
  project                    = var.project_id
  region                     = var.region
  scopes = [
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/logging.write"
  ]
  service_account         = "default"
  shared_vpc_host_project = null
  subnet_depend           = module.slurm_cluster_network.subnet_depend
  subnetwork_name         = null
  zone                    = var.zone
}
