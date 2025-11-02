import pandas as pd
import os
import shutil
from tqdm import tqdm

# Define the mapping from European car segment (car_class) to size class
CAR_CLASS_MAP = {
    'F': 'full',      # Luxury
    'E': 'full',      # Executive
    'D': 'midsize',   # Large
    'C': 'midsize',   # Medium
    'B': 'compact',   # Small
    'A': 'compact',   # Mini
    'S': 'compact',   # Sports cars
}

# Define a fallback mapping for body types not well-covered by car_class
BODY_TYPE_MAP = {
    'suv': 'suv',
    'crossover': 'suv',
    'pick-up': 'truck',
    'van': 'truck',
    'truck': 'truck',
    'pickup': 'truck',
}

def get_size_class(row):
    """Maps a car's data to a size class, prioritizing car_class."""
    car_class = row.get('car_class')
    body_type = row.get('Body_type')

    # 1. Prioritize car_class for standard cars
    if isinstance(car_class, str) and car_class in CAR_CLASS_MAP:
        return CAR_CLASS_MAP[car_class]

    # 2. Fallback to Body_type for SUVs and Trucks
    if isinstance(body_type, str):
        body_type_lower = body_type.lower()
        for key, value in BODY_TYPE_MAP.items():
            if key in body_type_lower:
                return value
    
    return None

def prepare_car_size_data(csv_path, images_dir, output_dir):
    """
    Prepares the car size training data by organizing images into size-based subdirectories.
    """
    # Clean and create output directories
    if os.path.exists(output_dir):
        print(f"Removing old processed data from {output_dir}...")
        shutil.rmtree(output_dir)
        
    print("Creating new directories...")
    for size in ['compact', 'midsize', 'full', 'suv', 'truck']:
        os.makedirs(os.path.join(output_dir, size), exist_ok=True)

    # Get all image filenames
    try:
        image_files = os.listdir(images_dir)
    except FileNotFoundError:
        print(f"Error: Images directory not found at {images_dir}")
        return

    # Create a dictionary to quickly find images by prefix
    images_by_prefix = {}
    for filename in image_files:
        parts = filename.split('_')
        if len(parts) >= 3:
            prefix = f"{parts[0]}_{parts[1]}_{parts[2]}"
            if prefix not in images_by_prefix:
                images_by_prefix[prefix] = []
            images_by_prefix[prefix].append(filename)

    # Process the CSV
    try:
        df = pd.read_csv(csv_path, low_memory=False)
        for _, row in tqdm(df.iterrows(), total=df.shape[0], desc="Processing CSV"):
            make = row['Make']
            model = row['Modle']
            year_val = row['Year_from']

            # Skip rows where year is not a valid number
            if pd.isna(year_val):
                continue
            
            year = int(year_val)

            size_class = get_size_class(row)
            if not size_class:
                continue

            # Find matching images and copy them
            prefix = f"{make}_{model}_{year}"
            if prefix in images_by_prefix:
                for filename in images_by_prefix[prefix]:
                    src_path = os.path.join(images_dir, filename)
                    dst_path = os.path.join(output_dir, size_class, filename)
                    if not os.path.exists(dst_path):
                        shutil.copy(src_path, dst_path)
    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_path}")
        return

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    CSV_FILE_PATH = os.path.join(script_dir, '../data/processed/car_specs_v0_filtered.csv')
    IMAGES_DIR = os.path.join(script_dir, '../data/cars')
    OUTPUT_DIR = os.path.join(script_dir, '../data/processed/car_sizes')

    prepare_car_size_data(CSV_FILE_PATH, IMAGES_DIR, OUTPUT_DIR)
    
    print("\nData preparation complete.")
    # Count the number of files in each directory
    for size in ['compact', 'midsize', 'full', 'suv', 'truck']:
        path = os.path.join(OUTPUT_DIR, size)
        if os.path.exists(path):
            num_files = len(os.listdir(path))
            print(f"Number of files in {size}: {num_files}")