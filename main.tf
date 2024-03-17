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

  allow {
    protocol = var.tcp
    ports    = var.firewall_deny
  }

  allow {
    protocol = var.udp
    ports    = var.firewall_deny
  }

  source_ranges = [var.dest_range]

  target_tags = ["${var.vpc}-${var.app_name}"]

}

resource "google_compute_network" "vpc" {
  provider                =   google-beta
  project = var.project_id
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

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
  deletion_policy = "ABANDON"
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

resource "google_sql_database_instance" "db_instance" {
  name = "db-instance"
  database_version = "MYSQL_8_0"
  region             = var.region
  deletion_protection = false
  depends_on = [google_service_networking_connection.default]
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
  name     = "webappnew"
  instance = google_sql_database_instance.db_instance.name
}

resource "google_sql_user" "db_user" {
  name     = "webappnew"
  instance = google_sql_database_instance.db_instance.name
  password = random_password.password.result
}

resource "random_password" "password" {
  length           = 8
  special          = true
}

resource "google_service_account" "service_account" {
  account_id   = "service-account-1"
  display_name = "service-account-1"
  project = "dev-assignment4"
}

resource "google_compute_instance" "vm_instance_webapp" {
  name         = var.vm_instance_name
  machine_type = var.machine_type
  zone         = var.zone

  service_account {
    email = var.service_email
   scopes =  ["cloud-platform"]
  }

  boot_disk {
    initialize_params {
      image = "projects/${var.project_id}/global/images/${var.image_name}"
      size  = var.image_size
      type  = var.image_type
    }
  }

  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.webapp.self_link
    access_config {
    }
  }
  tags = ["${var.vpc}-${var.app_name}", "http-server"]

  metadata = {
    startup-script=<<-EOT
  sudo bash -c 'cat > /opt/csye6225/webapp/.env'
  echo "db_database=${google_sql_database.database.name}" >> /opt/csye6225/webapp/.env
  echo "db_username=${google_sql_user.db_user.name}" >> /opt/csye6225/webapp/.env
  echo "db_password=${random_password.password.result}" >> /opt/csye6225/webapp/.env
  echo "db_host=${google_sql_database_instance.db_instance.private_ip_address}" >> /opt/csye6225/webapp/.env
  EOT
  }

  allow_stopping_for_update = true
}

resource "google_dns_record_set" "dns_record" {
  name    = var.azone
  type    = var.ztype
  ttl     = var.ttl
  managed_zone = var.zone_name
  rrdatas = [google_compute_instance.vm_instance_webapp.network_interface[0].access_config[0].nat_ip]
}

resource "google_project_iam_binding" "logging_admin" {
  project = var.project_id
  role = "roles/logging.admin"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}
resource "google_project_iam_binding" "monitoring_metric_writer" {
  project = var.project_id
  role = "roles/monitoring.editor"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}