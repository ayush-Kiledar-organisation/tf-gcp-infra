provider "google" {
  project = var.projecy_id
  region = var.region
  zone = var.zone
}

resource "google_compute_network" "vpc_1" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "webapp" {
  name          = var.subnet1
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc_1.self_link
}

resource "google_compute_subnetwork" "db" {
  name          = var.subnet2
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.vpc_1.self_link
}

resource "google_compute_route" "route_1" {
  name                   = var.route_name
  network                = google_compute_network.vpc_1.self_link
  dest_range             = "0.0.0.0/0"
  next_hop_gateway  = "default-internet-gateway"
}