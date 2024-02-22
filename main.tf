provider "google" {
  project = var.projecy_id
  region = var.region
  zone = var.zone
}

resource "google_compute_network" "vpc_1" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
  routing_mode       = var.routing_mode 
}

resource "google_compute_subnetwork" "webapp" {
  name          = var.subnet1
  ip_cidr_range = var.cidr1
  network       = google_compute_network.vpc_1.self_link
}

resource "google_compute_subnetwork" "db" {
  name          = var.subnet2
  ip_cidr_range = var.cidr2
  network       = google_compute_network.vpc_1.self_link
}

resource "google_compute_route" "route_1" {
  name                   = var.route_name
  network                = google_compute_network.vpc_1.self_link
  dest_range             = var.dest_range
  next_hop_gateway  = var.next_hop_gateway
}