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
  name = var.db_instance_name
  database_version = var.db_instance_version
  region             = var.region
  deletion_protection = false
  depends_on = [google_service_networking_connection.default]
  settings {
    tier = var.db_instance_tier
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
  name     = var.database_name
  instance = google_sql_database_instance.db_instance.name
}

resource "google_sql_user" "db_user" {
  name     = var.database_user
  instance = google_sql_database_instance.db_instance.name
  password = random_password.db_user_password.result
}

resource "random_password" "db_user_password" {
  length  = var.rm_len
  special = var.rm_special
}

resource "google_service_account" "service_account" {
  account_id   = var.service_id
  display_name = var.service_display_name
  project = var.project_id
}

# resource "google_compute_instance" "vm_instance_webapp" {
#   name         = var.vm_instance_name
#   machine_type = var.machine_type
#   zone         = var.zone

#   service_account {
#     email = var.service_email
#    scopes =  var.vm_service_roles
#   }
#   boot_disk {
#     initialize_params {
#       image = "projects/${var.project_id}/global/images/${var.image_name}"
#       size  = var.image_size
#       type  = var.image_type
#     }
#   }

#   network_interface {
#     network    = google_compute_network.vpc.self_link
#     subnetwork = google_compute_subnetwork.webapp.self_link
#     access_config {
#     }
#   }
#   tags = ["${var.vpc}-${var.app_name}", "http-server"]

#   metadata = {
#     startup-script = <<-SCRIPT
#     sudo bash <<EOF
#     cat <<INNER_EOF | sudo tee /opt/csye6225/webapp/.env > /dev/null
#     db_host=${google_sql_database_instance.db_instance.private_ip_address}
#     db_username=${google_sql_user.db_user.name}
#     db_password=${random_password.db_user_password.result}
#     db_database=${google_sql_database.database.name}
#     INNER_EOF
#     EOF
#     SCRIPT
#   }

#   allow_stopping_for_update = true
# }

resource "google_project_iam_binding" "vm_roles" {
  project = var.project_id
  role = "roles/compute.instanceAdmin.v1"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_project_iam_binding" "vm2_roles" {
  project = var.project_id
  role = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

# resource "google_dns_record_set" "dns_record" {
#   name    = var.azone
#   type    = var.ztype
#   ttl     = var.ttl
#   managed_zone = var.zone_name
#   rrdatas = [google_compute_instance.vm_instance_webapp.network_interface[0].access_config[0].nat_ip]
# }

resource "google_project_iam_binding" "logging_admin" {
  project = var.project_id
  role = var.logging_role
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}
resource "google_project_iam_binding" "monitoring_metric_writer" {
  project = var.project_id
  role = var.monitoring_role
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}
resource "google_pubsub_topic" "verify_email" {
  name = "verify_email"
  labels = {
    foo = "bar"
  }
  message_retention_duration = "604800s"
}

resource "google_pubsub_subscription" "cloud_sub" {
  name  = "cloud-sub"
  topic = google_pubsub_topic.verify_email.id
  labels = {
    foo = "bar"
  }
  retain_acked_messages      = true

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "604800s"
  }
  retry_policy {
    minimum_backoff = "10s"
  }
  enable_message_ordering    = false
}

resource "google_project_iam_binding" "token_creator" {
  project = var.project_id
  role = "roles/iam.serviceAccountTokenCreator"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

# resource "google_storage_bucket" "bucket" {
#   name     = "serverlerr-bucket"
#   location = "US"
# }

# resource "google_storage_bucket_object" "functioncode" {
#   name   = "serverless.zip"
#   bucket = google_storage_bucket.bucket.name
#   source = "serverless.zip"
# }

resource "google_vpc_access_connector" "connector" {
  name          = "webapp-vpc-connector"
  subnet {
    name = google_compute_subnetwork.connector_subnet.name
  }
  machine_type = "e2-standard-4"
}

resource "google_compute_subnetwork" "connector_subnet" {
  name          = "webapp-vpc-connector"
  ip_cidr_range = "10.2.0.0/28"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

# resource "google_cloudfunctions2_function" "default" {
#   name        = "cloud-webapp"
#   location    = "us-central1"
#   description = "a new function"

#   build_config {
#     runtime     = "nodejs18"
#     entry_point = "helloPubSub"
#     environment_variables = {
#       API_KEY = "${var.function_api_key}"
#       DOMAIN = "${var.function_domain}"
#     }
#     source {
#       storage_source {
#         bucket = google_storage_bucket.bucket.name
#         object = google_storage_bucket_object.functioncode.name
#       }
#     }
#   }

#   service_config {
#     max_instance_count = 3
#     min_instance_count = 1
#     available_memory   = "256M"
#     timeout_seconds    = 60
#     environment_variables = {
#       SERVICE_CONFIG_TEST = "config_test"
#       API_KEY = "${var.function_api_key}"
#       DOMAIN = "${var.function_domain}"
#       db_host="${google_sql_database_instance.db_instance.private_ip_address}"
#       db_username="${google_sql_user.db_user.name}"
#       db_password="${random_password.db_user_password.result}"
#       db_database="${google_sql_database.database.name}"
#     }

#     vpc_connector = google_vpc_access_connector.connector.name
#     ingress_settings               = "ALLOW_ALL"
#     vpc_connector_egress_settings = "VPC_CONNECTOR_EGRESS_SETTINGS_UNSPECIFIED"
#     all_traffic_on_latest_revision = true
#     service_account_email          = google_service_account.service_account.email
#   }

#   event_trigger {
#     trigger_region = var.region
#     event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
#     pubsub_topic   = google_pubsub_topic.verify_email.id
#     retry_policy   = "RETRY_POLICY_RETRY"
#   }
# }

# resource "google_cloudfunctions2_function_iam_member" "invoker" {
#   project        = var.project_id
#   cloud_function = google_cloudfunctions2_function.default.name

#   role   = "roles/cloudfunctions.invoker"
#   member = "serviceAccount:${google_service_account.service_account.email}"
# }

data "google_iam_policy" "a7viewer" {
  binding {
    role = "roles/viewer"
    members = [
      "serviceAccount:${google_service_account.service_account.email}",
    ]
  }
}

data "google_iam_policy" "a7editor" {
  binding {
    role = "roles/viewer"
    members = [
      "serviceAccount:${google_service_account.service_account.email}",
    ]
  }
}
resource "google_pubsub_subscription_iam_policy" "policy_subscription" {
  subscription = google_pubsub_subscription.cloud_sub.name
  policy_data  = data.google_iam_policy.a7editor.policy_data
}

# resource "google_pubsub_topic_iam_policy" "policy_topic" {
#   project = google_pubsub_topic.verify_email.project
#   topic = google_pubsub_topic.verify_email.name
#   policy_data = data.google_iam_policy.a7viewer.policy_data
# }

resource "google_pubsub_subscription_iam_binding" "editor" {
  subscription = google_pubsub_subscription.cloud_sub.name
  role         = "roles/editor"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_pubsub_subscription_iam_member" "editor" {
  subscription = google_pubsub_subscription.cloud_sub.name
  role         = "roles/editor"
  member       = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_pubsub_topic_iam_binding" "binding" {
  project = google_pubsub_topic.verify_email.project
  topic = google_pubsub_topic.verify_email.name
  role = "roles/viewer"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_pubsub_topic_iam_member" "member" {
  project = google_pubsub_topic.verify_email.project
  topic = google_pubsub_topic.verify_email.name
  role = "roles/viewer"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

# resource "google_cloudfunctions2_function_iam_policy" "policy" {
#   project = google_cloudfunctions2_function.default.project
#   cloud_function = google_cloudfunctions2_function.default.name
#   policy_data = data.google_iam_policy.a7viewer.policy_data
# }

# resource "google_cloudfunctions2_function_iam_binding" "binding2" {
#   project = google_cloudfunctions2_function.default.project
#   cloud_function = google_cloudfunctions2_function.default.name
#   role = "roles/viewer"
#   members = [
#     "serviceAccount:${google_service_account.service_account.email}",
#   ]
# }

# resource "google_cloudfunctions2_function_iam_member" "member2" {
#   project = google_cloudfunctions2_function.default.project
#   cloud_function = google_cloudfunctions2_function.default.name
#   role = "roles/viewer"
#   member = "serviceAccount:${google_service_account.service_account.email}"
# }

resource "google_compute_region_instance_template" "webapp_template" {
  name        = "webapp-template"
  description = "Webapp instance template."

  tags = ["${var.vpc}-${var.app_name}", "http-server"]

  labels = {
    environment = "dev"
  }

  instance_description = "description assigned to instances"
  machine_type         = "e2-medium"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image      = "projects/${var.project_id}/global/images/${var.image_name}"
    auto_delete       = true
    boot              = true
    resource_policies = [google_compute_resource_policy.daily_backup.id]
  }

  network_interface {
    network = "default"
  }

  metadata = {
    startup-script = <<-SCRIPT
      sudo bash <<EOF
      cat <<INNER_EOF | sudo tee /opt/csye6225/webapp/.env > /dev/null
      db_host=${google_sql_database_instance.db_instance.private_ip_address}
      db_username=${google_sql_user.db_user.name}
      db_password=${random_password.db_user_password.result}
      db_database=${google_sql_database.database.name}
      INNER_EOF
      EOF
      SCRIPT
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.service_account.email
    scopes = var.vm_service_roles
  }
}

resource "google_compute_region_disk" "temp_disk" {
  name  = "temp-disk"
  snapshot                  = google_compute_snapshot.snap-disk.id
  type                      = "pd-ssd"
  region                    = "us-central1"
  physical_block_size_bytes = 4096


  replica_zones = ["us-central1-a", "us-central1-f"]
}

resource "google_compute_disk" "disk" {
  name  = "disk"
  image = "projects/${var.project_id}/global/images/${var.image_name}"
  size  = 20
  type  = "pd-ssd"
  zone  = "us-central1-a"
}

resource "google_compute_snapshot" "snap-disk" {
  name        = "snap-disk-1"
  source_disk = google_compute_disk.disk.name
  zone        = "us-central1-a"
}

resource "google_compute_resource_policy" "daily_backup" {
  name   = "webappa-daily-backup"
  region = "us-central1"
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }
  }
}

resource "google_compute_health_check" "webappcheck" {
  name        = "tcp-health-check"
  description = "Health check via tcp"

  timeout_sec         = 10
  check_interval_sec  = 10
  healthy_threshold   = 1
  unhealthy_threshold = 5

  tcp_health_check {
    port = "3000"
  }
}

resource "google_compute_region_instance_group_manager" "webappserver" {

  provider = google-beta
  name = "webappserver-igm"
  project = var.project_id
  
  base_instance_name         = "app"
  region                     = "us-central1"
  distribution_policy_zones  = ["us-central1-a", "us-central1-f"]
  

  version {
    instance_template = google_compute_region_instance_template.webapp_template.self_link
  }

  # target_pools = []
  # target_size  = 2

  named_port {
    name = "app"
    port = 3000
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.webappcheck.id
    initial_delay_sec = 300
  }
}


resource "google_compute_region_autoscaler" "webappAutoScaler" {
  name   = "webapp-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.webappserver.id

  autoscaling_policy {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.05
    }
  }
}

resource "google_compute_managed_ssl_certificate" "webapp-ssl" {
  provider = google-beta
  name     = "webapp-ssl"
  project = var.project_id

  managed {
    domains = ["ayush-kiledar-webapp.me"]
  }
}

resource "google_compute_subnetwork" "lb-subnet" {
  name          = "lb-subnet"
  project = var.project_id
  provider      = google-beta
  ip_cidr_range = "10.129.0.0/23"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

resource "google_compute_global_address" "lb-address" {
  provider = google-beta
  project = var.project_id
  name     = "lb-static-ip"
}

resource "google_compute_global_forwarding_rule" "lb-forwarding-rule" {
  name                  = "lb-forwarding-rule"
  project = var.project_id
  provider              = google-beta
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.webapp-proxy.id
  ip_address            = google_compute_global_address.lb-address.id
  
}

resource "google_compute_target_https_proxy" "webapp-proxy" {
  name     = "webapp-target-http-proxy"
  project = var.project_id
  provider = google-beta
  url_map  = google_compute_url_map.urlmap.id
  ssl_certificates = [google_compute_managed_ssl_certificate.webapp-ssl.id]
  depends_on = [google_compute_managed_ssl_certificate.webapp-ssl]
}
resource "google_compute_url_map" "urlmap" {
  name            = "url-map"
  project = var.project_id
  provider        = google-beta
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_backend_service" "default" {
  name                    = "lb-backend-service"
  project                 = var.project_id
  provider                = google-beta
  protocol                = "HTTPS"
  load_balancing_scheme   = "EXTERNAL"
  timeout_sec             = 10
  port_name               = "app"
  health_checks           = [google_compute_health_check.webappcheck.id]
  backend {
    group           = google_compute_region_instance_group_manager.webappserver.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}