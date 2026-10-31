import json
import subprocess
import sys

QUERY = """
SELECT COALESCE(
    jsonb_agg(to_jsonb(p) ORDER BY p.id),
    '[]'::jsonb
)
FROM public.products AS p;
"""


def read_products(database):
    result = subprocess.check_output(
        [
            "docker", "exec",
            "-e", "PGTZ=UTC",
            "tf-three-tier-db",
            "psql",
            "-X",
            "-U", "stockuser",
            "-d", database,
            "-v", "ON_ERROR_STOP=1",
            "-At",
            "-c", QUERY,
        ],
        text=True,
    )
    return json.loads(result)


try:
    original = read_products("stockdb")
    restored = read_products("stockdb_restore_test")
except (subprocess.CalledProcessError, json.JSONDecodeError) as error:
    print(f"ERROR: Verifikasi tidak dapat dijalankan: {error}")
    sys.exit(1)

if original != restored:
    print("FAIL: Data products hasil restore berbeda dari database asli.")
    sys.exit(1)

print(f"PASS: {len(original)} produk identik pada kedua database.")