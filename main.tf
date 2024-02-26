provider "google" {
  project     = var.project_id
  region      = var.region
}


resource "google_compute_firewall" "allow_request" {
  name     = var.firname
  network  = google_compute_network.vpc.self_link

  allow {
    protocol = var.tcp
    ports    = var.firewall_allow
  }

  source_ranges = [var.dest_range]

  target_tags = ["${var.vpc}-${var.app_name}", "http-server"]
}

resource "google_compute_firewall" "deny_tcp" {
  name     = var.deny_tcp
  network  = google_compute_network.vpc.self_link

  deny {
    protocol = var.tcp
    ports    = var.firewall_deny
  }

  deny {
    protocol = var.udp
    ports    = var.firewall_deny
  }

  source_ranges = [var.dest_range]

  target_tags = ["${var.vpc}-${var.app_name}"]

}

resource "google_compute_network" "vpc" {
  provider                =   google-beta
  name                            = var.vpc
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp" {
  provider                = google-beta
  project = google_compute_network.vpc.project
  name          = "${var.vpc}-${var.app_name}"
  ip_cidr_range = var.cidr1
  network       = google_compute_network.vpc.self_link
  region        = var.region
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "db" {
  provider                = google-beta
  project = google_compute_network.vpc.project
  name          = "${var.vpc}-${var.db_name}"
  ip_cidr_range = var.cidr2
  network       = google_compute_network.vpc.self_link
  region        = var.region
  private_ip_google_access = true
}
# add-ons

resource "google_compute_global_address" "private_ip_address" {
  name         = "private-ip-address"
  address_type = "INTERNAL"
  purpose      = "VPC_PEERING"
  network      = google_compute_network.vpc.id
  prefix_length = 16
}
# resource "google_compute_global_forwarding_rule" "default" {
#   provider              = google-beta
#   project               = google_compute_network.vpc.project
#   name                  = "globalrule"
#   target                = "all-apis"
#   network               = google_compute_network.vpc.id
#   ip_address            = google_compute_global_address.default.id
#   load_balancing_scheme = ""
# }

resource "google_compute_route" "webapp" {
  name             = "${var.vpc}-route"
  dest_range       = var.dest_range
  network          = google_compute_network.vpc.name
  next_hop_gateway = var.gateway
  priority         = 1000
  tags             = ["${var.vpc}-${var.app_name}"]
}

# resource "google_compute_instance" "vm_instance_webapp" {
#   for_each     = google_compute_network.vpc
#   name         = var.vm_instance_name
#   machine_type = var.machine_type
#   zone         = var.zone

#   boot_disk {
#     initialize_params {
#       image = "projects/${var.project_id}/global/images/${var.image_name}"
#       size  = var.image_size
#       type  = var.image_type
#     }
#   }

#   network_interface {
#     network    = each.value.self_link
#     subnetwork = google_compute_subnetwork.webapp[each.key].self_link
#     access_config {
#     }
#   }
#   tags = ["${each.key}-${var.app_name}", "http-server"]
# }

resource "google_sql_database_instance" "db_instance" {
  name = "db-instance"
  database_version = "MYSQL_8_0"
  region             = var.region
  deletion_protection = false
  settings {
    tier = "db-f1-micro"
    disk_type = var.disk_type
    disk_size = var.disk_size
    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.vpc.self_link
    }
    backup_configuration {
      enabled = true
      binary_log_enabled = true
    }
    availability_type = var.availability_type
    
  
  }
}

resource "google_sql_database" "database" {
  name     = "webapp"
  instance = google_sql_database_instance.db_instance.name
}

resource "google_sql_user" "db_user" {
  name     = "webapp"
  instance = google_sql_database_instance.db_instance.name
  password = random_password.password.result
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}