resource "docker_image" "api" {
  name = "ghcr.io/reyhanhad/stock-api:${var.api_image_tag}"

  keep_locally = true
}

resource "docker_container" "api" {
  name    = "tf-three-tier-api"
  image   = docker_image.api.image_id
  restart = "unless-stopped"

  wait         = true
  wait_timeout = 120

  env = [
    "PORT=3000",
    "DB_HOST=db",
    "DB_PORT=5432",
    "POSTGRES_USER=stockuser",
    "POSTGRES_DB=stockdb",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]

  networks_advanced {
    name        = docker_network.app.name
    aliases     = ["api"]
    gw_priority = 1
  }

  networks_advanced {
    name = docker_network.database.name
  }

  healthcheck {
    test = [
      "CMD",
      "node",
      "-e",
      "fetch('http://127.0.0.1:3000/ready').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))",
    ]

    interval     = "5s"
    timeout      = "3s"
    retries      = 10
    start_period = "10s"
  }

  depends_on = [docker_container.db]
}