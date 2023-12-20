variable "public_vpc_id" {
  description = "The ID of the vpc where the lb will be placed."
}

variable "public_subnet_id" {
  description = "The ID of the subnet where the lb will be placed."
}

variable "traffic_lb_ip" {
  description = "Static external IP address for traffic load balancer from network module."
}

variable "instance_group" {
  description = "Unmanaged Instance Group"
}

resource "google_compute_health_check" "http_health_check" {
  name               = "http-health-check"
  check_interval_sec = 30
  timeout_sec        = 5
  tcp_health_check {
    port = "80"
  }
  healthy_threshold   = 2
  unhealthy_threshold = 2
  log_config {
    enable = true
  }
}

resource "google_compute_backend_service" "backend_svc" {
  name        = "http-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  log_config {
    enable = true
  }
  enable_cdn = false

  backend {
    group = var.instance_group
    balancing_mode               = "UTILIZATION"
    capacity_scaler              = 1
    max_utilization              = 1
  }
  health_checks = [google_compute_health_check.http_health_check.id]
}

resource "google_compute_url_map" "url_map" {
  name        = "traffic-load-balancer"
  default_service = google_compute_backend_service.backend_svc.self_link
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name             = "traffic-load-balancer-target-proxy"
  url_map          = google_compute_url_map.url_map.self_link
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name = "http-proxy"
  load_balancing_scheme = "EXTERNAL"
  target = google_compute_target_http_proxy.http_proxy.self_link
  port_range = "80-80"
  ip_protocol = "TCP"
}
