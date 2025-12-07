
import argparse
import pandas as pd
import torch
import time
from torch.utils.data import Dataset, DataLoader
from torchvision import models, transforms
from PIL import Image
import torch.nn as nn
from sklearn.metrics import precision_recall_fscore_support, accuracy_score
import numpy as np
from pathlib import Path

class CarDataset(Dataset):
    def __init__(self, csv_file, transform=None, label_to_idx=None):
        self.dataframe = pd.read_csv(csv_file)
        self.transform = transform
        if label_to_idx is None:
            # Create a mapping from string labels to integer indices if not provided
            self.label_to_idx = {label: i for i, label in enumerate(self.dataframe['label'].unique())}
        else:
            self.label_to_idx = label_to_idx
        self.idx_to_label = {i: label for label, i in self.label_to_idx.items()}

    def __len__(self):
        return len(self.dataframe)

    def __getitem__(self, idx):
        img_path = self.dataframe.iloc[idx, 0]
        image = Image.open(img_path).convert('RGB')
        label_str = self.dataframe.iloc[idx, 1]
        label_idx = self.label_to_idx[label_str]
        
        if self.transform:
            image = self.transform(image)
            
        return image, label_idx

def evaluate_classifier(model, dataloader, device, num_classes):
    model.eval()
    all_preds = []
    all_labels = []
    
    total_inference_time = 0.0
    total_images = 0

    with torch.no_grad():
        for inputs, labels in dataloader:
            inputs = inputs.to(device)
            labels = labels.to(device)
            
            # Start timing
            if device.type == 'mps':
                torch.mps.synchronize()
            elif device.type == 'cuda':
                torch.cuda.synchronize()
            
            start_time = time.time()
            outputs = model(inputs)
            
            # End timing
            if device.type == 'mps':
                torch.mps.synchronize()
            elif device.type == 'cuda':
                torch.cuda.synchronize()
            
            end_time = time.time()
            
            total_inference_time += (end_time - start_time)
            total_images += inputs.size(0)

            _, preds = torch.max(outputs, 1)
            
            all_preds.extend(preds.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())

    avg_inference_time_ms = (total_inference_time / total_images) * 1000 if total_images > 0 else 0

    # Overall metrics
    accuracy = accuracy_score(all_labels, all_preds)
    precision, recall, f1, _ = precision_recall_fscore_support(all_labels, all_preds, average='macro')
    
    print(f"Overall Accuracy: {accuracy:.4f}")
    print(f"Macro-F1 Score: {f1:.4f}")
    print(f"Macro-Precision: {precision:.4f}")
    print(f"Macro-Recall: {recall:.4f}")
    print(f"Average Inference Time per Image: {avg_inference_time_ms:.2f} ms")

    # Per-class metrics
    p_class, r_class, f1_class, _ = precision_recall_fscore_support(all_labels, all_preds, average=None, labels=range(num_classes))
    
    # Get class names from dataset
    idx_to_label = dataloader.dataset.idx_to_label
    
    print("\nPer-class metrics:")
    for i in range(num_classes):
        class_name = idx_to_label.get(i, f"Class {i}")
        print(f"  Class '{class_name}':")
        print(f"    Precision: {p_class[i]:.4f}")
        print(f"    Recall:    {r_class[i]:.4f}")
        print(f"    F1-score:  {f1_class[i]:.4f}")

def main():
    parser = argparse.ArgumentParser(description="Evaluate a car classification model.")
    parser.add_argument("--model_path", type=str, default="/app/models/car_classifier_best.pt", help="Path to the trained model.")
    parser.add_argument("--data_csv", type=str, default="/app/data/processed/car_classification_valid.csv", help="Path to the evaluation CSV.")
    parser.add_argument("--batch_size", type=int, default=16, help="Evaluation batch size.")
    parser.add_argument("--num-workers", type=int, default=2, help="Number of workers for the dataloader.")
    parser.add_argument("--model-name", type=str, default="efficientnet_b0", help="Model name used for training (e.g., efficientnet_b0).")
    parser.add_argument("--train_csv", type=str, default="/app/data/processed/car_classification_train.csv", help="Path to the training CSV to get label mapping.")


    args = parser.parse_args()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")

    # Data transformations
    data_transforms = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    # Create datasets and dataloaders
    # We need the training dataset to ensure the label_to_idx mapping is the same
    train_dataset = CarDataset(csv_file=args.train_csv)
    eval_dataset = CarDataset(csv_file=args.data_csv, transform=data_transforms, label_to_idx=train_dataset.label_to_idx)
    
    eval_loader = DataLoader(eval_dataset, batch_size=args.batch_size, shuffle=False, num_workers=args.num_workers)
    
    num_classes = len(eval_dataset.label_to_idx)
    print(f"Number of classes: {num_classes}")

    # Load pre-trained model and modify the final layer
    print(f"Loading model architecture {args.model_name}...")
    if args.model_name == 'efficientnet_b1':
        model = models.efficientnet_b1(weights=None)
        num_ftrs = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(num_ftrs, num_classes)
    elif args.model_name == 'efficientnet_b2':
        model = models.efficientnet_b2(weights=None)
        num_ftrs = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(num_ftrs, num_classes)
    elif args.model_name == 'efficientnet_b3':
        model = models.efficientnet_b3(weights=None)
        num_ftrs = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(num_ftrs, num_classes)
    elif args.model_name == 'resnet18':
        model = models.resnet18(weights=None)
        num_ftrs = model.fc.in_features
        model.fc = nn.Linear(num_ftrs, num_classes)
    else: # Default to efficientnet_b0
        model = models.efficientnet_b0(weights=None)
        num_ftrs = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(num_ftrs, num_classes)
    
    model = model.to(device)

    # Load the trained weights
    print(f"Loading trained weights from {args.model_path}")
    model.load_state_dict(torch.load(args.model_path, map_location=device))
    model = model.to(device)

    # Evaluate the model
    evaluate_classifier(model, eval_loader, device, num_classes)

if __name__ == "__main__":
    main()
