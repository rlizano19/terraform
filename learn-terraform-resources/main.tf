provider "google" {

  credentials = file(var.credentials)

  project = var.project 
  region  = var.region 
  zone    = var.zone 
}

provider "random" {}

resource "random_pet" "name" {}

resource "google_compute_instance" "web" {
  name         = random_pet.name.id
  machine_type = "g1-small"
  tags         = ["http-server"]
  metadata_startup_script = file("init-script.sh")

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    network = "default"
    access_config {
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

output "domain-name" {
  value = google_compute_instance.web.network_interface.0.access_config.0.nat_ip
}

output "application-url" {
  value = "${google_compute_instance.web.network_interface.0.access_config.0.nat_ip}/index.php"
}