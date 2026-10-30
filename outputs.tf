output "web_url" {
  description = "URL aplikasi melalui Nginx"
  value       = "http://127.0.0.1:${var.web_port}"
}