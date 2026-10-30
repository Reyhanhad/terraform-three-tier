variable "db_password" {
  description = "Password PostgreSQL untuk lab tiga lapis"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "Password minimal 16 karakter."
  }
}
variable "api_image_tag" {
  description = "SHA commit untuk image Stock API"
  type        = string
  default     = "636b17bdabef303a168ae8712fb1f94977e790fa"

  validation {
    condition     = can(regex("^[0-9a-f]{40}$", var.api_image_tag))
    error_message = "Tag harus berupa SHA lengkap: 40 karakter heksadesimal lowercase."
  }
}

variable "web_port" {
  description = "Port lokal untuk mengakses aplikasi melalui Nginx"
  type        = number
  default     = 8083

  validation {
    condition = (
      var.web_port >= 1024 &&
      var.web_port <= 65535 &&
      floor(var.web_port) == var.web_port
    )
    error_message = "Port harus bilangan bulat antara 1024 dan 65535."
  }
}