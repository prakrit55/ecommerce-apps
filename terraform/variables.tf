variable "project_id" {
  type        = string
  default     = "k8s-staging-252732"
  description = "The GCP Project ID where resources will be created."
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The GCP region for the network resources."
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "The GCP zone for the VM instance."
}

variable "instance_name" {
  type        = string
  default     = "ecom-app-instance"
  description = "Name of the Compute Engine VM instance."
}

variable "machine_type" {
  type        = string
  default     = "e2-medium" # 2 vCPUs, 4 GB RAM
  description = "The machine type to use for the VM instance."
}

variable "boot_disk_image" {
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
  description = "OS Image for the GCE boot disk."
}
