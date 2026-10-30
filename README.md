# Terraform Three-Tier Stock API

Provision a local three-tier application using Terraform and Docker:
Nginx as the reverse proxy, a Node.js Stock API, and PostgreSQL.

## Architecture

| Component | Docker networks | Published port |
| --- | --- | --- |
| Nginx | app | 127.0.0.1:8083 |
| Stock API | app, database | None |
| PostgreSQL | database | None |

Requests enter through Nginx and are forwarded to the API.
The API accesses PostgreSQL through a separate internal network.

PostgreSQL stores its data in the named volume
`tf-three-tier-postgres-data`.

Terraform manages nine resources:
three images, three containers, two networks, and one volume.

## Requirements

- Linux with Docker running
- Access to `/var/run/docker.sock`
- Terraform 1.17.x
- Local port 8083 available
- Internet access for initial provider and image downloads

## Images

- Nginx: `nginx:1.30.6-alpine`
- PostgreSQL: `postgres:17.11-alpine`
- Stock API: `ghcr.io/reyhanhad/stock-api`, tagged with a full commit SHA

The provider dependency lock file is committed to Git.

## Setup

From the project directory:

```bash
terraform init
```

For a fresh checkout, copy the example variables:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Replace the example `db_password` with a random password of at least
16 characters. Reuse an existing local variable file instead of
overwriting it.

Restrict access to the variable file:

```bash
chmod 600 terraform.tfvars
```

Validate and review the deployment:

```bash
terraform fmt -check
terraform validate
terraform plan -out=deploy.tfplan
```

For a fresh deployment, expect nine resources to be created.
Review the plan before applying:

```bash
terraform apply deploy.tfplan
```

## Verification

```bash
curl -fsS http://127.0.0.1:8083/ready
curl -fsS http://127.0.0.1:8083/products
terraform state list
terraform plan
```

Expected results:

- `/ready` reports `ready` and `database: connected`.
- `/products` returns a JSON array.
- Terraform tracks nine resources.
- A subsequent plan reports no changes.

Check container health:

```bash
docker inspect tf-three-tier-nginx tf-three-tier-api tf-three-tier-db --format '{{.Name}}: {{.State.Health.Status}}'
```

## Startup and Health Checks

Terraform waits for PostgreSQL to become healthy before creating
the API, then waits for the API before creating Nginx.

The API health check calls `/ready`, which queries PostgreSQL.
The Nginx health check calls `/ready` through the reverse proxy.

All three containers use `restart = "unless-stopped"`.

Nginx uses Docker DNS with dynamic upstream resolution so it can
refresh the API address when its container IP changes.

## Database Initialization

The SQL file in `db/init/` creates the `products` table during the
first database initialization.

Initialization scripts only run when the data directory is empty.
Editing the SQL file does not migrate an existing database.

Changing `db_password` in Terraform does not rotate the password
inside an already initialized PostgreSQL database.

## Verified Persistence Test

A product was created through Nginx before replacing the database
container:

```bash
terraform plan -replace=docker_container.db -out=persistence.tfplan
```

The reviewed plan replaced only the database container and retained
the named volume.

```bash
terraform apply persistence.tfplan
```

After replacement:

- The database container had a new ID.
- The API returned to readiness.
- Existing products remained available.
- Terraform reported no changes.

This verifies persistence across container replacement.
Backup and restore have not yet been tested.

## State and Credentials

Local variable files, Terraform state, saved plans, and downloaded
providers are excluded from Git.

Sensitive variables are hidden from normal CLI output, but credentials
remain present in local state and saved plans. Protect those files.

Keep the state file available while managing this infrastructure.

## Volume Protection

The database volume uses `prevent_destroy = true`.
Terraform rejects a full destroy plan while this protection remains
in the configuration.

Removing the volume requires a deliberate configuration change.
Back up any required data before removing that protection.

## Scope

This is a local learning environment with one instance per component.
It demonstrates network separation, health checks, persistent storage,
and infrastructure management.

TLS, high availability, and database roles with restricted application
permissions are not implemented.
