#!/bin/bash
# Script to initialize parking stall data in the database.

echo "Running init_stalls.sh..."

# Iterate through each lot individually to ensure all are loaded
for lot_id in lot_a lot_b lot_c lot_d lot_e; do
  # Check if stalls are already loaded for this specific lot
  if python -c "from app.db import get_db; from app.models import Stall; db = next(get_db()); print(db.query(Stall).filter_by(lot_id='$lot_id').first() is not None)" | grep -q "True"; then
    echo "  Stall data already present for $lot_id. Skipping."
  else
    echo "  Stall data not found for $lot_id. Loading..."
    python scripts/load_stalls.py --file "/app/data/parking_lot_geojson/${lot_id}_data.geojson" --lot-id "$lot_id"
    if [ $? -ne 0 ]; then
      echo "  Error loading stalls for $lot_id. Aborting."
      exit 1
    fi
  fi
done

echo "init_stalls.sh finished."
