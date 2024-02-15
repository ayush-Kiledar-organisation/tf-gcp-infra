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