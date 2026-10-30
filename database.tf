resource "docker_image" "postgres" {
  name         = "postgres:17.11-alpine"
  keep_locally = true
}

resource "docker_container" "db" {
  name    = "tf-three-tier-db"
  image   = docker_image.postgres.image_id
  restart = "unless-stopped"

  wait         = true
  wait_timeout = 120

  env = [
    "POSTGRES_USER=stockuser",
    "POSTGRES_DB=stockdb",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]

  networks_advanced {
    name    = docker_network.database.name
    aliases = ["db"]
  }

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  upload {
    file = "/docker-entrypoint-initdb.d/001-create-products.sql"

    content = file(
      "${path.module}/db/init/001-create-products.sql"
    )

    permissions = "0644"
  }

  healthcheck {
    test = [
      "CMD",
      "pg_isready",
      "-h", "127.0.0.1",
      "-U", "stockuser",
      "-d", "stockdb",
    ]

    interval     = "5s"
    timeout      = "3s"
    retries      = 10
    start_period = "10s"
  }
}