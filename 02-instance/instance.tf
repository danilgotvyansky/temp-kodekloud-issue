variable "private_vpc_id" {
  description = "Application VPC ID from network module"
  type = string
}

variable "private_subnet_id" {
  description = "Private subnet ID from network module"
  type = string
}

variable "service_account_email" {
  description = "An email of the Compute Engine default service account"
  type = string
}

variable "instance_count" {
  description = "Number of instances to create"
}

variable "static_ips" {
  description = "Static IPs from network module"
  type = list(string)
}

resource "google_compute_instance" "instance" {
  count        = var.instance_count
  name         = "instance-${count.index+1}"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  tags = ["http-server", "https-server", "lb-health-check", "ssh"]

  boot_disk {
    auto_delete = true
    device_name = "instance-${count.index+1}"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2310-mantic-amd64-v20231031"
      size  = 10
      type  = "pd-standard"
    }

    mode = "READ_WRITE"
  }

  network_interface {
    subnetwork = var.private_subnet_id
    access_config {
      nat_ip = var.static_ips[count.index]
    }
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/sqlservice.admin", "https://www.googleapis.com/auth/compute", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/logging.admin", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/trace.append", "https://www.googleapis.com/auth/devstorage.read_only"]
  }

}

resource "google_compute_instance_group" "unmanaged_instance_group" {
  name        = "unmanaged-instance-group-1"
  description = "An unmanaged instance group created with Terraform"
  network     = var.private_vpc_id
  zone        = "us-central1-a"

  named_port {
    name = "http"
    port = 80
  }

  depends_on = [google_compute_instance.instance]
}

resource "null_resource" "add_instance_to_group" {
  count = var.instance_count
  depends_on = [google_compute_instance.instance, google_compute_instance_group.unmanaged_instance_group]

  provisioner "local-exec" {
    command = "gcloud compute instance-groups unmanaged add-instances ${google_compute_instance_group.unmanaged_instance_group.name} --instances=${google_compute_instance.instance[count.index].name} --zone=us-central1-a"
  }
}

output "unmanaged_instance_group" {
  description = "Unanaged Instance Group"
  value       = google_compute_instance_group.unmanaged_instance_group.self_link
}

output "internal_ips" {
  description = "Internal IP addresses of the instances"
  value = google_compute_instance.instance.*.network_interface[0].network_ip
}
