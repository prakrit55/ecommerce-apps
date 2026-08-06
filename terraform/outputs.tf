output "instance_public_ip" {
  value       = google_compute_instance.ecom_instance.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the deployed e-commerce application VM instance."
}

output "application_ui_url" {
  value       = "http://${google_compute_instance.ecom_instance.network_interface[0].access_config[0].nat_ip}:4000"
  description = "URL to access the E-commerce UI dashboard."
}

output "prometheus_dashboard_url" {
  value       = "http://${google_compute_instance.ecom_instance.network_interface[0].access_config[0].nat_ip}:9092"
  description = "URL to access the Prometheus Dashboard."
}
