
import argparse
import pandas as pd
import torch
from torchvision import models, transforms
from PIL import Image
import torch.nn as nn
from pathlib import Path

def predict_size(model_path, image_path, train_csv_path):
    """
    Predicts the size of a car in an image using a trained classifier.

    Args:
        model_path (str): Path to the trained model file.
        image_path (str): Path to the image to be classified.
        train_csv_path (str): Path to the training CSV file to get label mappings.
    """
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # Load label mapping from the training data
    try:
        dataframe = pd.read_csv(train_csv_path)
        label_to_idx = {label: i for i, label in enumerate(dataframe['label'].unique())}
        idx_to_label = {i: label for label, i in label_to_idx.items()}
        num_classes = len(label_to_idx)
    except FileNotFoundError:
        print(f"Error: Training CSV not found at {train_csv_path}")
        return

    # Load the model structure
    model = models.resnet18(weights=None)
    num_ftrs = model.fc.in_features
    model.fc = nn.Linear(num_ftrs, num_classes)

    # Load the trained weights
    try:
        model.load_state_dict(torch.load(model_path, map_location=device))
    except FileNotFoundError:
        print(f"Error: Model not found at {model_path}")
        return
        
    model = model.to(device)
    model.eval()

    # Image transformations
    transform = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    # Load and transform the image
    try:
        image = Image.open(image_path).convert('RGB')
    except FileNotFoundError:
        print(f"Error: Image not found at {image_path}")
        return
        
    image = transform(image).unsqueeze(0)  # Add batch dimension
    image = image.to(device)

    # Make prediction
    with torch.no_grad():
        outputs = model(image)
        _, preds = torch.max(outputs, 1)
        predicted_label = idx_to_label[preds.item()]

    print(f"The predicted size for the car in '{Path(image_path).name}' is: {predicted_label}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Predict car size from an image.")
    parser.add_argument("--model_path", type=str, default="/app/models/car_classifier_best.pt", help="Path to the trained model.")
    parser.add_argument("--image_path", type=str, required=True, help="Path to the car image.")
    parser.add_argument("--train_csv", type=str, default="/app/data/processed/car_classification_train.csv", help="Path to the training CSV for label mapping.")
    args = parser.parse_args()

    predict_size(args.model_path, args.image_path, args.train_csv)
