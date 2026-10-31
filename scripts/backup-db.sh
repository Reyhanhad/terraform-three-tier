#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

umask 077
mkdir -p backups

backup_stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_tmp="$(mktemp "backups/stockdb_${backup_stamp}_XXXXXX")"
backup_file="${backup_tmp}.dump"

trap 'rm -f -- "$backup_tmp"' EXIT

docker exec tf-three-tier-db \
  pg_dump -U stockuser -d stockdb -Fc \
  > "$backup_tmp"

docker exec -i tf-three-tier-db \
  pg_restore --list \
  < "$backup_tmp" > /dev/null

mv -- "$backup_tmp" "$backup_file"

printf 'Backup dibuat: %s\n' "$backup_file"
printf 'Arsip berhasil dibaca oleh pg_restore.\n'