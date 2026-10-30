resource "docker_volume" "postgres_data" {
  name = "tf-three-tier-postgres-data"

  lifecycle {
    prevent_destroy = true
  }
}