output "instance_id" {
  value       = aws_instance.ecom_instance.id
  description = "The EC2 Instance ID."
}

output "instance_public_ip" {
  value       = aws_instance.ecom_instance.public_ip
  description = "The public IPv4 address of the deployed e-commerce EC2 instance."
}

output "instance_public_dns" {
  value       = aws_instance.ecom_instance.public_dns
  description = "The public DNS name of the EC2 instance."
}

output "application_ui_url" {
  value       = "http://${aws_instance.ecom_instance.public_ip}:4000"
  description = "URL to access the E-Commerce Web UI Portal."
}

output "prometheus_dashboard_url" {
  value       = "http://${aws_instance.ecom_instance.public_ip}:9092"
  description = "URL to access the Prometheus Monitoring Dashboard."
}

output "grafana_dashboard_url" {
  value       = "http://${aws_instance.ecom_instance.public_ip}:3000"
  description = "URL to access Grafana Dashboards."
}

output "netdata_dashboard_url" {
  value       = "http://${aws_instance.ecom_instance.public_ip}:19999"
  description = "URL to access Netdata Real-time System Metrics."
}

output "ssh_command" {
  value       = "ssh -i <YOUR_KEY_PAIR.pem> ubuntu@${aws_instance.ecom_instance.public_ip}"
  description = "SSH command to connect to the EC2 instance."
}
