terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)

  project = var.project 
  region  = var.region 
  zone    = var.zone 
}

#VPC -> Default


#Firewall rule for MIG instances
resource "google_compute_firewall" "default" {
  name    = "default-allow-http-80"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["http-server"]
  description = "Allow port 80 access to http-server"
}


#LB



#LB Firewall



#Health Check for MIG
resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/healthz"
    port         = "8080"
  }
}

#Instance Template
resource "google_compute_instance_template" "instance_template" {
  name_prefix  = "instance-template-"
  machine_type = "g1-small"
  region       = "us-central1"
  tags         = ["http-server"]
  metadata_startup_script = file("startup-script.sh")

  disk {
    source_image = "centos-cloud/centos-7"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#Managed Instance Group
resource "google_compute_instance_group_manager" "instance_group_manager" {
  name               = "instance-group-manager"
  instance_template  = google_compute_instance_template.instance_template.id
  base_instance_name = "instance-group-manager"
  zone               = "us-central1-a"
  target_size        = "2"
  named_port {
    name = "customHTTP"
    port = 8888
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}




