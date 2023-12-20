variable "project_id" {
  description = "The ID of the project in which resources will be provisioned."
  default     = "clgcporg8-076" # Enter playground project ID.
}

variable "compute_service_account_email" {
  description = "An email of the Compute Engine default service account"
  default     = "369400310347-compute@developer.gserviceaccount.com" # Enter compute service account email ID from playground.
}

variable "resource_count" {
  description = "Number of instances and IPs to create"
  default     = "1"
}

provider "google" {
 project = var.project_id
 region  = "us-central1"
}

module "network" {
  source   = "./01-network"
  ip_count = var.resource_count
}

module "instance" {
  source                = "./02-instance"
  private_vpc_id        = module.network.private_vpc_id
  private_subnet_id     = module.network.private_subnet_id
  service_account_email = var.compute_service_account_email
  instance_count        = var.resource_count
  static_ips            = module.network.static_ips
}

module "load-balancer" {
  source           = "./03-load-balancer"
  public_vpc_id    = module.network.public_vpc_id
  public_subnet_id = module.network.public_subnet_id
  traffic_lb_ip    = module.network.traffic_lb_ip
  instance_group   = module.instance.unmanaged_instance_group
}
