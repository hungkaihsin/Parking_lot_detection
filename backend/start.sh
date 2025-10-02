#!/usr/bin/env bash
set -e

echo "DATABASE_URL (SQLAlchemy): $DATABASE_URL"

python - <<'PY'
import os, time, psycopg2
host = "db"; port = 5432
user = os.getenv("POSTGRES_USER", "postgres")
password = os.getenv("POSTGRES_PASSWORD", "password")
dbname = os.getenv("POSTGRES_DB", "parkinglot")
dsn = f"dbname={dbname} user={user} password={password} host={host} port={port}"
print("Connecting with DSN:", dsn.replace(password, "******"))
for i in range(60):
    try:
        psycopg2.connect(dsn).close()
        print("DB reachable."); break
    except Exception as e:
        print(f"Wait {i+1} — {e}"); time.sleep(1)
else:
    raise SystemExit("DB not ready after waiting.")
PY

alembic upgrade head

echo "Loading parking lot data..."
python scripts/load_stalls.py --file $(python -c "import os; print(os.path.join('data', 'lot_a_layout.geojson'))") --lot-id LotA
python scripts/load_stalls.py --file $(python -c "import os; print(os.path.join('data', 'lot_b_layout.geojson'))") --lot-id LotB
echo "Data loading complete."

exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
