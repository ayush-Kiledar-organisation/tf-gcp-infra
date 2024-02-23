provider "google" {
  project     = var.project_id
  region      = var.region
}


resource "google_compute_firewall" "allow_request" {

  for_each = google_compute_network.vpc
  name     = var.firname
  network  = each.value.self_link

  allow {
    protocol = var.tcp
    ports    = var.firewall_allow
  }

  source_ranges = [var.dest_range]

  target_tags = ["${each.key}-${var.app_name}", "http-server"]
}

resource "google_compute_firewall" "deny_tcp" {
  for_each = google_compute_network.vpc
  name     = var.deny_tcp
  network  = each.value.self_link

  deny {
    protocol = var.tcp
    ports    = var.firewall_deny
  }

  deny {
    protocol = var.udp
    ports    = var.firewall_deny
  }

  source_ranges = [var.dest_range]

  target_tags = ["${each.key}-${var.app_name}"]

}

resource "google_compute_network" "vpc" {
  for_each                        = toset(var.vpcs)
  name                            = each.key
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true

}

resource "google_compute_subnetwork" "webapp" {
  for_each      = google_compute_network.vpc
  name          = "${each.key}-${var.app_name}"
  ip_cidr_range = var.cidr1
  network       = each.value.self_link
  region        = var.region
}

resource "google_compute_subnetwork" "db" {
  for_each      = google_compute_network.vpc
  name          = "${each.key}-${var.db_name}"
  ip_cidr_range = var.cidr2
  network       = each.value.self_link
  region        = var.region
}

resource "google_compute_route" "webapp" {
  for_each         = google_compute_network.vpc
  name             = "${each.key}-route"
  dest_range       = var.dest_range
  network          = each.value.name
  next_hop_gateway = var.gateway
  priority         = 1000
  tags             = ["${each.key}-${var.app_name}"]
}

resource "google_compute_instance" "vm_instance_webapp" {
  for_each     = google_compute_network.vpc
  name         = var.vm_instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "projects/${var.project_id}/global/images/${var.image_name}"
      size  = var.image_size
      type  = var.image_type
    }
  }

  network_interface {
    network    = each.value.self_link
    subnetwork = google_compute_subnetwork.webapp[each.key].self_link
    access_config {
    }
  }
  tags = ["${each.key}-${var.app_name}", "http-server"]
}
