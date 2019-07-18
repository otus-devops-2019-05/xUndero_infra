resource "google_compute_instance_group" "reddit-cluster" {
  name        = "reddit-cluster"
  description = "Terraform test instance group"

  instances = [
    "${google_compute_instance.app.*.self_link}",
  ]

  named_port {
    name = "reddit-app"
    port = "9292"
  }

  zone = "${var.zone}"
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "global-rule"
  target     = "${google_compute_target_http_proxy.default.self_link}"
  port_range = "8080"
}

resource "google_compute_target_http_proxy" "default" {
  name        = "target-proxy"
  description = "a description"
  url_map     = "${google_compute_url_map.default.self_link}"
}

resource "google_compute_url_map" "default" {
  name            = "url-map-target-proxy"
  description     = "a description"
  default_service = "${google_compute_backend_service.reddit-backend.self_link}"

  /*  host_rule {
        hosts        = ["mysite.com"]
        path_matcher = "allpaths"
      }
    
  path_matcher {
    name            = "allpaths"
    default_service = "${google_compute_backend_service.reddit-backend.self_link}"

    path_rule {
      paths   = ["/*"]
      service = "${google_compute_backend_service.reddit-backend.self_link}"
    }
  }*/
}

resource "google_compute_backend_service" "reddit-backend" {
  name             = "reddit-backend"
  port_name        = "reddit-app"
  protocol         = "HTTP"
  timeout_sec      = 10
  session_affinity = "NONE"

  backend {
    group = "${google_compute_instance_group.reddit-cluster.self_link}"
  }

  health_checks = ["${google_compute_http_health_check.reddit-health.self_link}"]
}

resource "google_compute_http_health_check" "reddit-health" {
  name = "reddit-health"

  #  request_path       = "/"
  #  check_interval_sec = 10
  #  timeout_sec        = 5
  port = 9292
}
