variable "projecy_id" {
    type = string
  description = "The ID of current project"
  default = "terraform-assignment-414415"
  
}

variable "region" {
  type = string
  description = "The region of the resources"
  default = "us-central1" 
}

variable "zone" {
  type = string
  description = "The zone of the resources"
  default = "us-central1-c"
  
}

variable "vpc_name" {
  type = string
  description = "The name of the VPC"
  default = "vpc-1" 
}

variable "route_name" {
  type = string
  description = "The name of the route"
  default = "route-1"  
}

variable "subnet1" {
  type = string
  description = "Subnet 1"
  default = "webapp"  
}

variable "subnet2" {
  type = string
  description = "Subnet 2"
  default = "db"
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

variable routing_mode {
  type = string
  description = "routing mode of VPC"
  default = "REGIONAL"
}

variable "dest_range" {
  type = string
  description = "destination range"
  default = "0.0.0.0/0"
  
}

variable "next_hop_gateway" {
  type = string
  description = "next hop gateway"
  default = "default-internet-gateway"
  
}