#!/bin/bash
# Script to initialize parking stall data in the database.

echo "Running init_stalls.sh..."

# Database wait is handled in start.sh, so we can proceed directly.

# Check if stalls are already loaded for any lot (e.g., lot_a).
# This makes the script idempotent - it only loads data if the DB is empty.
if python -c "from app.db import get_db; from app.models import Stall; db = next(get_db()); print(db.query(Stall).filter_by(lot_id='lot_a').first() is not None)" | grep -q "True"; then
  echo "Stall data already present for lot_a. Skipping initialization."
else
  echo "Stall data not found for lot_a. Initializing all lots..."
  for lot_id in lot_a lot_b lot_c lot_d lot_e; do
    echo "  Loading stalls for $lot_id..."
    python scripts/load_stalls.py --file "/app/data/parking_lot_geojson/${lot_id}_data.geojson" --lot-id "$lot_id"
    if [ $? -ne 0 ]; then
      echo "  Error loading stalls for $lot_id. Aborting."
      exit 1
    fi
  done
  echo "All stall data initialized."
fi

echo "init_stalls.sh finished."
