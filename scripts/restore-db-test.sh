#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'Penggunaan: bash scripts/restore-db-test.sh PATH_BACKUP\n' >&2
  exit 2
fi

backup_file="$1"
restore_db="stockdb_restore_test"

if [[ ! -f "$backup_file" || ! -r "$backup_file" || ! -s "$backup_file" ]]; then
  printf 'ERROR: File backup tidak tersedia, tidak terbaca, atau kosong.\n' >&2
  exit 1
fi

docker exec -i tf-three-tier-db \
  pg_restore --list \
  < "$backup_file" > /dev/null

database_exists="$(
  docker exec tf-three-tier-db \
    psql -X -U stockuser -d postgres \
    -v ON_ERROR_STOP=1 -At \
    -c "SELECT 1 FROM pg_database WHERE datname = 'stockdb_restore_test';"
)"

if [[ "$database_exists" != "1" ]]; then
  docker exec tf-three-tier-db \
    createdb -U stockuser -T template0 "$restore_db"
fi

printf 'Memulihkan %s ke %s...\n' "$backup_file" "$restore_db"

docker exec -i tf-three-tier-db \
  pg_restore \
    -U stockuser \
    -d "$restore_db" \
    --clean \
    --if-exists \
    --single-transaction \
  < "$backup_file"

printf 'Restore ke %s berhasil.\n' "$restore_db"