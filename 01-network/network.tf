variable ip_count {
  description = "Number of IPs to create"
  type = string
}

# a VPC for private resources
resource "google_compute_network" "application_private_vpc" {
  name                    = "application-private-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.application_private_vpc.id
  region        = "us-central1"
}

resource "google_compute_address" "static" {
  count = var.ip_count
  name = "static-ip-address-${count.index+1}"
  region = "us-central1"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# a VPC for public resources
resource "google_compute_network" "traffic_public_vpc" {
  name                    = "traffic-public-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.1.0.0/16"
  network       = google_compute_network.traffic_public_vpc.id
  region        = "us-central1"
}

resource "google_compute_address" "traffic_lb_ip" {
  name = "traffic-lb-ip"
  region = "us-central1"
}

locals {
  joined_ips = join(",", google_compute_address.static.*.address)
}

resource "google_compute_firewall" "allow-ssh-to-static-ips" {
  name    = "allow-ssh-to-static-ips"
  network = google_compute_network.application_private_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges   = ["0.0.0.0/0"]
  destination_ranges = [local.joined_ips]
  direction = "INGRESS"
  priority  = 1000
  target_tags = ["ssh"]
}

#resource "google_compute_firewall" "deny-all-to-static-ips" {
#  name    = "deny-all-to-static-ips"
#  network = google_compute_network.application_private_vpc.name
#
#  deny {
#    protocol = "all"
#  }
#
#  source_ranges   = ["0.0.0.0/0"]
#  destination_ranges = [local.joined_ips]
#  target_tags = ["ssh"]
#  priority = 2000
#}

resource "google_compute_firewall" "allow-all-in-subnet" {
  name    = "allow-all-in-subnet"
  network = google_compute_network.application_private_vpc.name

  allow {
    protocol = "all"
  }

  source_ranges     = ["0.0.0.0/0"]
  destination_ranges = [google_compute_subnetwork.private_subnet.ip_cidr_range]
}

resource "google_compute_firewall" "application-allow-egress" {
  name                     = "application-allow-egress"
  network                  = google_compute_network.application_private_vpc.name
  direction                = "EGRESS"
  destination_ranges       = ["0.0.0.0/0"]

  allow {
    protocol               = "all"
  }
}

# Output for created external static IPs
output "static_ips" {
  description = "The static IPs for the instances"
  value = google_compute_address.static.*.address
}

output "traffic_lb_ip" {
  description = "Static external IP address for traffic load balancer."
  value = google_compute_address.traffic_lb_ip.address
}

# Output for Application Private VPC
output "private_vpc_id" {
    value = google_compute_network.application_private_vpc.id
    description = "The ID of the Private VPC network"
}

# Output for Private Subnet
output "private_subnet_id" {
  value = google_compute_subnetwork.private_subnet.id
  description = "The ID of the private subnet"
}

output "private_subnet_cidr" {
  value = google_compute_subnetwork.private_subnet.ip_cidr_range
  description = "The IP CIDR range of the private subnet"
}

# Output for Traffic Public VPC
output "public_vpc_id" {
  value = google_compute_network.traffic_public_vpc.id
  description = "The ID of the public VPC network"
}

# Output for Public Subnet
output "public_subnet_id" {
  value = google_compute_subnetwork.public_subnet.id
  description = "The ID of the public subnet"
}

output "public_subnet_cidr" {
  value = google_compute_subnetwork.public_subnet.ip_cidr_range
  description = "The IP CIDR range of the public subnet"
}
