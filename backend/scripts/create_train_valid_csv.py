import os
import pandas as pd
from sklearn.model_selection import train_test_split
import argparse

def create_train_valid_csv(data_dir, output_dir, train_split=0.8):
    """
    Creates training and validation CSV files from a directory of labeled images.
    """
    image_paths = []
    labels = []

    for size_class in ['compact', 'midsize', 'full', 'suv', 'truck']:
        class_dir = os.path.join(data_dir, size_class)
        if not os.path.isdir(class_dir):
            continue
        for filename in os.listdir(class_dir):
            if filename.endswith(('.jpg', '.jpeg', '.png')):
                # The training script expects paths relative to /app
                image_path = os.path.join('data/processed/car_sizes', size_class, filename)
                image_paths.append(image_path)
                labels.append(size_class)

    if not image_paths:
        print("No images found. Exiting.")
        return

    # Create a DataFrame
    df = pd.DataFrame({'image_path': image_paths, 'label': labels})

    # Split the data
    train_df, valid_df = train_test_split(df, train_size=train_split, stratify=df['label'], random_state=42)

    # Save the CSV files
    os.makedirs(output_dir, exist_ok=True)
    train_csv_path = os.path.join(output_dir, 'car_classification_train.csv')
    valid_csv_path = os.path.join(output_dir, 'car_classification_valid.csv')

    train_df.to_csv(train_csv_path, index=False)
    valid_df.to_csv(valid_csv_path, index=False)

    print(f"Created {train_csv_path} with {len(train_df)} samples.")
    print(f"Created {valid_csv_path} with {len(valid_df)} samples.")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Create training and validation CSV files.")
    parser.add_argument("--data_dir", type=str, default="/app/data/processed/car_sizes", help="Path to the processed data directory.")
    parser.add_argument("--output_dir", type=str, default="/app/data/processed", help="Directory to save the CSV files.")
    args = parser.parse_args()

    create_train_valid_csv(args.data_dir, args.output_dir)
