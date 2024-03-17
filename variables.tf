#variables.tf

variable "project_id" {
  type = string
  default = "dev-assignment4"
  description = "Project ID"
}

variable "region" {
  type = string
  default = "us-central1"
  description = "The region"
}

variable "auto_create_subnetworks" {
  type = bool
  default = false
  description = "Auto Create subnetworks"
}

variable "routing_mode" {
  type = string
  description = "routing mode of VPC"
  default = "REGIONAL"
}

variable "zone" {
  type = string
  description = "The zone of the resources"
  default = "us-central1-c"
}

variable "cidr1" {
  type = string
  description = "range 1"
  default = "10.0.1.0/24"
}
variable "cidr2" {
  type = string
  description = "range 2"
  default = "10.0.2.0/24" 
}

variable "route_name" {
  type = string
  description = "The name of the route"
  default = "route-1" 
}

variable "dest_range" {
  type = string
  description = "destination range"
  default = "0.0.0.0/0"
}

variable "vm_instance_name" {
  type = string
  description = "The name of the VM instance"
  default = "webapp-instance"
}

variable "machine_type" {
  type = string
  description = "The machine type of the VM instance"
  default = "n1-standard-1"
}

variable "image_name" {
  type = string
  description = "The name of the custom image"
  default = "myimage3"
}

variable "image_size" {
  default = "100"
}

variable "image_type" {
  default = "pd-standard"
}

variable "firewall_deny" {
  default = ["22"]
}

variable "firewall_allow" {
  default = ["3000", "8080"]
}

variable "tcp" {
  type = string
  default = "tcp"
  description = "name of tcp"
}

variable "udp" {
  type = string
  default = "udp"
  description = "name of udp"
  
}

variable "app_name" {
  type = string
  default = "webapp"
  description = "The name of the app"
  
}

variable "vpc" {
  description = "list of all vpc"
  type        = string
  default     = "new-vpc"
}

variable "db_name" {
  type = string
  default = "db"
  description = "name of db"
  
}

variable "gateway" {
  type = string
  default = "default-internet-gateway"
  description = "default-internet-gateway"
  
}

variable "firname" {
  type = string
  default = "allow-request"
  description = "name of firewall"
  
}

variable "deny_tcp" {
  type = string
  default = "deny-all"
  description = "name of deny firewall"
}

variable "disk_type" {
  type    = string
  default = "pd-ssd"
}

variable "disk_size" {
  type    = number
  default = 100
}

variable "ipv4_enabled" {
  type    = bool
  default = false
}

variable "private_network" {
  type    = string
  default = "YOUR_CUSTOM_VPC"
}

variable "availability_type" {
  type    = string
  default = "REGIONAL"
}

variable "azone" {
  type    = string
  default = "ayush-kiledar-webapp.me." 
}

variable "ztype" {
  type    = string
  default = "A" 
}

variable "ttl" {
  type    = number
  default = 300  
}

variable "zone_name" {
  type    = string
  default = "webapp-zone"
}

variable "service_email" {
  type    = string
  default = "service-account-1@dev-assignment4.iam.gserviceaccount.com"
}