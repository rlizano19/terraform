variable "project" { }

variable "credentials" { }

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable image_family {
  description = "Image used for compute VMs."
  default     = "debian-9"
}

variable image_project {
  description = "GCP Project where source image comes from."
  default     = "debian-cloud"
}