terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
    google-beta = {
      version = ">= 2.7.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)

  project = var.project 
  region  = var.region 
  zone    = var.zone 
}

provider "google-beta" {
  project = var.project
}

#VPC -> Default


#Firewall rule for MIG instances
# resource "google_compute_firewall" "default" {
#   name    = "default-allow-http-80"
#   network = "default"

#   allow {
#     protocol = "tcp"
#     ports    = ["80"]
#   }

#   source_ranges = ["0.0.0.0/0"]
#   target_tags = ["http-server"]
#   description = "Allow port 80 access to http-server"
# }

#Health Check for MIG
# resource "google_compute_health_check" "autohealing" {
#   name                = "autohealing-health-check"
#   check_interval_sec  = 5
#   timeout_sec         = 5
#   healthy_threshold   = 2
#   unhealthy_threshold = 10 # 50 seconds

#   http_health_check {
#     request_path = "/healthz"
#     port         = "8080"
#   }
# }

data "template_file" "instance_startup_script" {
  template = file("${path.module}/templates/gceme.sh.tpl")

  vars = {
    PROXY_PATH = ""
  }
}

resource "google_service_account" "instance-group" {
  account_id = "instance-group"
}

module "instance_template" {
  source               = "terraform-google-modules/vm/google//modules/instance_template"
  version              = "~> 1.0.0"
  subnetwork           = google_compute_subnetwork.subnetwork.self_link
  source_image_family  = var.image_family
  source_image_project = var.image_project
  startup_script       = data.template_file.instance_startup_script.rendered

  service_account = {
    email  = google_service_account.instance-group.email
    scopes = ["cloud-platform"]
  }
}

module "managed_instance_group" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "~> 1.0.0"
  region            = var.region
  target_size       = 2
  hostname          = "mig-simple"
  instance_template = module.instance_template.self_link

  target_pools = [
    module.gce-lb-fr.target_pool
  ]

  named_ports = [{
    name = "http"
    port = 80
  }]
}

#Instance Template
# resource "google_compute_instance_template" "instance_template" {
#   name_prefix  = "instance-template-"
#   machine_type = "g1-small"
#   region       = "us-central1"
#   tags         = ["http-server"]
#   metadata_startup_script = data.template_file.instance_startup_script.rendered

#   disk {
#     source_image = "centos-cloud/centos-7"
#     auto_delete  = true
#     boot         = true
#   }

#   network_interface {
#     network = "default"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

#Managed Instance Group
# resource "google_compute_instance_group_manager" "instance_group_manager" {
#   name               = "instance-group-manager"
#   version {
#     instance_template  = google_compute_instance_template.instance_template.id
#   }
#   base_instance_name = "instance-group-manager"
#   zone               = "us-central1-a"
#   target_size        = "2"
#   named_port {
#     name = "customHTTP"
#     port = 8888
#   }

#   auto_healing_policies {
#     health_check      = google_compute_health_check.autohealing.id
#     initial_delay_sec = 300
#   }
# }

module "gce-lb-fr" {
  source       = "github.com/GoogleCloudPlatform/terraform-google-lb"
  region       = var.region
  name         = "group1-lb"
  service_port = "80"
  target_tags  = ["http-server"]
  target_service_accounts = [google_service_account.instance-group.email]
}

#LB Firewall




# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A NETWORK LOAD BALANCER
# This module deploys a GCP Regional Network Load Balancer
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------------------------------------------------------
# CREATE FORWARDING RULE
# ------------------------------------------------------------------------------

# resource "google_compute_forwarding_rule" "default" {
#   provider              = google-beta
#   project               = var.project
#   name                  = var.name
#   target                = google_compute_target_pool.default.self_link
#   load_balancing_scheme = "EXTERNAL"
#   port_range            = var.port_range
#   ip_address            = var.ip_address
#   ip_protocol           = var.protocol

#   labels = var.custom_labels
# }

# # ------------------------------------------------------------------------------
# # CREATE TARGET POOL
# # ------------------------------------------------------------------------------

# resource "google_compute_target_pool" "default" {
#   provider         = google-beta
#   project          = var.project
#   name             = "${var.name}-tp"
#   region           = var.region
#   session_affinity = var.session_affinity

#   instances = var.instances

#   health_checks = google_compute_http_health_check.default.*.name
# }

# # ------------------------------------------------------------------------------
# # CREATE HEALTH CHECK
# # ------------------------------------------------------------------------------

# resource "google_compute_http_health_check" "default" {
#   count = var.enable_health_check ? 1 : 0

#   provider            = google-beta
#   project             = var.project
#   name                = "${var.name}-hc"
#   request_path        = var.health_check_path
#   port                = var.health_check_port
#   check_interval_sec  = var.health_check_interval
#   healthy_threshold   = var.health_check_healthy_threshold
#   unhealthy_threshold = var.health_check_unhealthy_threshold
#   timeout_sec         = var.health_check_timeout
# }

# # ------------------------------------------------------------------------------
# # CREATE FIREWALL FOR THE HEALTH CHECKS
# # ------------------------------------------------------------------------------

# # Health check firewall allows ingress tcp traffic from the health check IP addresses
# resource "google_compute_firewall" "health_check" {
#   count = var.enable_health_check ? 1 : 0

#   provider = google-beta
#   project  = var.network_project == null ? var.project : var.network_project
#   name     = "${var.name}-hc-fw"
#   network  = var.network

#   allow {
#     protocol = "tcp"
#     ports    = [var.health_check_port]
#   }

#   # These IP ranges are required for health checks
#   source_ranges = ["209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16"]

#   # Target tags define the instances to which the rule applies
#   target_tags = var.firewall_target_tags
# }