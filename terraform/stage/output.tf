output "app_external_ip" {
  value = ["${module.app.app_external_ip}"]
}

/*output "lb_ip" {
  value = "${google_compute_global_forwarding_rule.default.ip_address}"
}*/

output "db_internal_ip" {
  value = "${module.db.db_internal_ip}"
}
