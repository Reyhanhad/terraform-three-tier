resource "docker_network" "app" {
  name   = "tf-three-tier-app"
  driver = "bridge"
}

resource "docker_network" "database" {
  name     = "tf-three-tier-database"
  driver   = "bridge"
  internal = true
}