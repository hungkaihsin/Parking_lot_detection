import argparse
import pandas as pd
from pathlib import Path
import re
from sklearn.model_selection import train_test_split

def parse_brand_model_from_filename(fname: str):
    """Assumes names like 'Acura_ILX_2013_...jpg' -> brand='Acura', model='ILX' (best effort)."""
    base = Path(fname).stem
    parts = re.split(r"[_\s\-]", base)
    brand = parts[0] if parts else ""
    model = parts[1] if len(parts) > 1 else ""
    return brand.title(), model.upper()

def main():
    parser = argparse.ArgumentParser(description="Prepare car classification dataset.")
    parser.add_argument("--image_dir", type=str, default="/app/data/car/", help="Directory containing car images.")
    parser.add_argument("--csv_path", type=str, default="/app/data/processed/car_specs_v0_filtered.csv", help="Path to the car specifications CSV.")
    parser.add_argument("--output_dir", type=str, default="/app/data/processed/", help="Directory to save the output CSVs.")
    args = parser.parse_args()

    image_dir = Path(args.image_dir)
    csv_path = Path(args.csv_path)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    print("Loading car specifications CSV...")
    # Using low_memory=False to handle the DtypeWarning
    spec_df = pd.read_csv(csv_path, low_memory=False)
    
    # Create a unique target label from Make and Model
    # Correcting the typo 'Modle' to 'Model' if it exists
    model_col = 'Modle' if 'Modle' in spec_df.columns else 'model'
    spec_df['target_label'] = spec_df['Make'].str.strip() + "_" + spec_df[model_col].str.strip()
    
    print("Processing image files...")
    image_files = list(image_dir.glob('**/*.jpg'))
    
    dataset = []
    for img_path in image_files:
        brand, model = parse_brand_model_from_filename(img_path.name)
        
        # Find the corresponding target label
        # This assumes the user has already cleaned the CSV so matches will be found
        match = spec_df[(spec_df['Make'].str.lower() == brand.lower()) & (spec_df[model_col].str.lower() == model.lower())]
        
        if not match.empty:
            target = match.iloc[0]['target_label']
            dataset.append({'image_path': str(img_path), 'label': target})

    if not dataset:
        print("Error: No matching images and labels found. Please ensure filenames match the CSV content.")
        return

    dataset_df = pd.DataFrame(dataset)
    
    print(f"Found {len(dataset_df)} images with corresponding labels.")
    print(f"Number of unique car models: {dataset_df['label'].nunique()}")

    print("Checking for classes with only one sample...")
    label_counts = dataset_df['label'].value_counts()
    single_sample_labels = label_counts[label_counts == 1].index.tolist()

    if single_sample_labels:
        print(f"Found {len(single_sample_labels)} classes with only one sample. Removing them.")
        dataset_df = dataset_df[~dataset_df['label'].isin(single_sample_labels)]

    print(f"Proceeding with {len(dataset_df)} images and {dataset_df['label'].nunique()} classes.")

    print("Splitting data into training and validation sets (80/20)...")
    train_df, valid_df = train_test_split(dataset_df, test_size=0.2, random_state=42, stratify=dataset_df['label'])

    train_path = output_dir / 'car_classification_train.csv'
    valid_path = output_dir / 'car_classification_valid.csv'

    train_df.to_csv(train_path, index=False)
    valid_df.to_csv(valid_path, index=False)

    print(f"\nDataset preparation complete.")
    print(f"Training set saved to: {train_path}")
    print(f"Validation set saved to: {valid_path}")

if __name__ == "__main__":
    main()
