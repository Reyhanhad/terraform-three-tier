resource "docker_image" "nginx" {
  name         = "nginx:1.30.6-alpine"
  keep_locally = true
}

resource "docker_container" "nginx" {
  name    = "tf-three-tier-nginx"
  image   = docker_image.nginx.image_id
  restart = "unless-stopped"

  wait         = true
  wait_timeout = 120

  networks_advanced {
    name = docker_network.app.name
  }

  ports {
    internal = 80
    external = var.web_port
    ip       = "127.0.0.1"
  }

  upload {
    file        = "/etc/nginx/conf.d/default.conf"
    content     = file("${path.module}/nginx/default.conf")
    permissions = "0644"
  }

  healthcheck {
    test = [
      "CMD",
      "wget",
      "-q",
      "-O",
      "/dev/null",
      "http://127.0.0.1/ready",
    ]

    interval     = "5s"
    timeout      = "3s"
    retries      = 10
    start_period = "10s"
  }

  depends_on = [docker_container.api]
}