import json
import os
import sys
import argparse
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from shapely.geometry import shape, Point
from shapely import wkt

# Add the project root to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.models import Base, Stall, StallFeature, stall_neighbors
from app.db import DATABASE_URL

def get_db_session():
    """Initializes and returns a new database session."""
    engine = create_engine(DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    return SessionLocal()

def load_stalls_from_geojson(db, geojson_path, lot_id):
    """
    Loads stall data from a GeoJSON file into the database for a specific lot.

    This function is idempotent for a given lot_id. It first clears all existing
    stall-related data for that lot_id before loading the new data.
    """
    print(f"Starting stall data load for lot: {lot_id} from {geojson_path}...")

    # 1. Idempotency: Clear existing data for the specified lot_id
    print(f"Clearing existing stall data for lot: {lot_id}...")
    # This is more complex to do correctly for neighbors, so for now we still clear the whole table.
    # A more advanced implementation would handle this more granularly.
    db.execute(text(f"DELETE FROM {stall_neighbors.name}")) 
    db.query(StallFeature).filter(StallFeature.id.in_(
        db.query(Stall.id).filter(Stall.lot_id == lot_id)
    )).delete(synchronize_session=False)
    db.query(Stall).filter(Stall.lot_id == lot_id).delete(synchronize_session=False)
    db.commit()
    print("Existing data cleared.")

    # 2. Load GeoJSON file
    with open(geojson_path, 'r') as f:
        geojson_data = json.load(f)

    # 3. Find the entrance point first
    entrance_feature = next((f for f in geojson_data['features'] if f['properties'].get('id') == 'ENTRANCE'), None)
    if not entrance_feature or entrance_feature['geometry']['type'] != 'Point':
        raise ValueError("Could not find a valid 'ENTRANCE' Point feature in the GeoJSON.")
    entrance_point = Point(entrance_feature['geometry']['coordinates'])
    print(f"Found entrance at {entrance_point.wkt}")

    # 4. Process and create stall objects
    stalls_to_create = []
    geom_map = {}  # Store in-memory shapely objects
    for feature in geojson_data['features']:
        if feature['geometry']['type'] == 'Polygon':
            geom = shape(feature['geometry'])
            props = feature['properties']
            
            stall_id = props.get('id')
            if not stall_id:
                print(f"Skipping feature with no ID: {props}")
                continue

            geom_map[stall_id] = geom  # Save the geom object

            # Create Stall
            new_stall = Stall(
                id=stall_id,
                lot_id=lot_id,  # Use the provided lot_id
                geom_wkt=geom.wkt,
                center_x=geom.centroid.x,
                center_y=geom.centroid.y
            )

            # Create StallFeature
            new_feature = StallFeature(
                id=stall_id,
                is_ada=props.get('is_ada', False),
                is_ev=props.get('is_ev', False),
                connectors=props.get('connectors'),
                width_class=props.get('width_class'),
                dist_to_entrance=geom.centroid.distance(entrance_point)
            )
            
            # Link them
            new_stall.features = new_feature
            stalls_to_create.append(new_stall)
            print(f"Prepared stall {stall_id} for creation.")

    if not stalls_to_create:
        print("No valid stall polygons found to load.")
        return

    db.add_all(stalls_to_create)
    
    # 5. Calculate neighbors (for all stalls in the DB for simplicity)
    # A more advanced version would only calculate for the current lot.
    print("Calculating neighbors...")
    all_stalls_in_db = db.query(Stall).all()
    for stall_a in all_stalls_in_db:
        geom_a = wkt.loads(stall_a.geom_wkt)
        for stall_b in all_stalls_in_db:
            if stall_a.id == stall_b.id:
                continue
            
            geom_b = wkt.loads(stall_b.geom_wkt)
            if geom_a.touches(geom_b):
                stall_a.neighbors.append(stall_b)
                print(f"  - {stall_a.id} and {stall_b.id} are neighbors.")

    # 6. Commit transaction
    print("Committing all new data to the database...")
    db.commit()
    print(f"Stall data load for lot {lot_id} complete.")

def main():
    """Main function to parse arguments and run the loader."""
    parser = argparse.ArgumentParser(description="Load parking stall data from a GeoJSON file.")
    parser.add_argument("--file", required=True, help="Path to the GeoJSON source file.")
    parser.add_argument("--lot-id", required=True, help="The Lot ID to assign to the stalls (e.g., LotA).")
    args = parser.parse_args()

    db_session = get_db_session()
    try:
        load_stalls_from_geojson(db_session, args.file, args.lot_id)
    finally:
        db_session.close()

if __name__ == "__main__":
    main()