import json
import os

# 1. Define the mapping from image paths to new filenames
mapping = {
    "148521975.png": "lot_a_data.geojson",
    "156886202.png": "lot_b_data.geojson",
    "219035790.png": "lot_c_data.geojson",
    "190423072.png": "lot_d_data.geojson",
    "386442953.png": "lot_e_data.geojson"
}

# 2. Create a new dictionary to store the 'features' for each lot
lots_data = {image_path: [] for image_path in mapping.keys()}

# 3. Loop through both lot_a_layout.json and lot_b_layout.json
layout_files = [
    "../data/lot_a_layout.geojson",
    "../data/lot_b_layout.geojson"
]

for file_path in layout_files:
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
            
            # 4. For each 'feature' (stall) inside the JSON, read the imagePath
            for feature in data.get("features", []):
                properties = feature.get("properties", {})
                image_path = properties.get("imagePath")
                
                # 5. Add that feature to the correct list in the lots_data dictionary
                if image_path in lots_data:
                    lots_data[image_path].append(feature)
                    
    except FileNotFoundError:
        print(f"Warning: File not found at {file_path}")
    except json.JSONDecodeError:
        print(f"Warning: Could not decode JSON from {file_path}")

# 6. Loop through the mapping and save the new JSON files
output_dir = "../data"
os.makedirs(output_dir, exist_ok=True) # Create the output directory if it doesn't exist

for image_path, new_filename in mapping.items():
    # Create the GeoJSON FeatureCollection structure
    output_data = {
        "type": "FeatureCollection",
        "features": lots_data[image_path]
    }
    
    # Save the data to the new file
    # The new files will be created in the ../data directory
    output_path = os.path.join(output_dir, new_filename)
    with open(output_path, 'w') as f:
        json.dump(output_data, f, indent=2)
        
    print(f"Saved {len(lots_data[image_path])} features to {new_filename}")

print("\nScript finished.")
