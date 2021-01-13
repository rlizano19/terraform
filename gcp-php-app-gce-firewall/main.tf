provider "google" {

  credentials = file(var.credentials)

  project = var.project 
  region  = var.region 
  zone    = var.zone 
}

provider "random" {}

resource "random_pet" "name" {}

#resource "google_compute_address" "vm_static_ip" {
#  name = "terraform-static-ip"
#}

resource "google_compute_instance" "vm_instance" {
  name         = random_pet.name.id
  machine_type = "g1-small"
  tags         = ["http-server"]
  metadata_startup_script = file("init-script.sh")
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {
#      nat_ip = google_compute_address.vm_static_ip.address
    }
  }
}

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

# resource "google_compute_network" "default" {
#   name = "vpc-network"
# }

output "domain-name" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}

output "application-url" {
  value = "${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip}/index.php"
}
