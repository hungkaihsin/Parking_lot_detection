import argparse
import pandas as pd
import torch
from torch.utils.data import Dataset, DataLoader
from torchvision import models, transforms
from PIL import Image
import torch.nn as nn
import torch.optim as optim
from pathlib import Path

# 1. Custom Dataset Class
class CarDataset(Dataset):
    def __init__(self, csv_file, transform=None):
        self.dataframe = pd.read_csv(csv_file)
        self.transform = transform
        # Create a mapping from string labels to integer indices
        self.label_to_idx = {label: i for i, label in enumerate(self.dataframe['label'].unique())}
        self.idx_to_label = {i: label for label, i in self.label_to_idx.items()}

    def __len__(self):
        return len(self.dataframe)

    def __getitem__(self, idx):
        img_path = self.dataframe.iloc[idx, 0]
        # Make sure image path is absolute or relative to a known root
        # In our docker container, paths are relative to /app
        image = Image.open(img_path).convert('RGB')
        label_str = self.dataframe.iloc[idx, 1]
        label_idx = self.label_to_idx[label_str]
        
        if self.transform:
            image = self.transform(image)
            
        return image, label_idx

# 2. Training and Validation Functions
def train_model(model, train_loader, criterion, optimizer, device):
    model.train()
    running_loss = 0.0
    correct_predictions = 0
    
    for i, (inputs, labels) in enumerate(train_loader):
        inputs = inputs.to(device)
        labels = labels.to(device)
        
        optimizer.zero_grad()
        
        outputs = model(inputs)
        loss = criterion(outputs, labels)
        
        _, preds = torch.max(outputs, 1)
        
        loss.backward()
        optimizer.step()
        
        running_loss += loss.item() * inputs.size(0)
        correct_predictions += torch.sum(preds == labels.data)

        if i % 10 == 0:
            print(f"  Batch {i}/{len(train_loader)}, Loss: {loss.item():.4f}")

    epoch_loss = running_loss / len(train_loader.dataset)
    epoch_acc = correct_predictions.double() / len(train_loader.dataset)
    
    return epoch_loss, epoch_acc

def validate_model(model, valid_loader, criterion, device):
    model.eval()
    running_loss = 0.0
    correct_predictions = 0
    
    with torch.no_grad():
        for inputs, labels in valid_loader:
            inputs = inputs.to(device)
            labels = labels.to(device)
            
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            
            _, preds = torch.max(outputs, 1)
            
            running_loss += loss.item() * inputs.size(0)
            correct_predictions += torch.sum(preds == labels.data)
            
    epoch_loss = running_loss / len(valid_loader.dataset)
    epoch_acc = correct_predictions.double() / len(valid_loader.dataset)
    
    return epoch_loss, epoch_acc

# 3. Main Execution Block
def main():
    parser = argparse.ArgumentParser(description="Train a car classification model.")
    parser.add_argument("--train_csv", type=str, default="/app/data/processed/car_classification_train.csv", help="Path to the training CSV.")
    parser.add_argument("--valid_csv", type=str, default="/app/data/processed/car_classification_valid.csv", help="Path to the validation CSV.")
    parser.add_argument("--model_dir", type=str, default="/app/models/", help="Directory to save the trained model.")
    parser.add_argument("--epochs", type=int, default=25, help="Number of training epochs.")
    parser.add_argument("--batch_size", type=int, default=16, help="Training batch size.")
    parser.add_argument("--lr", type=float, default=0.001, help="Learning rate.")
    parser.add_argument("--num-workers", type=int, default=2, help="Number of workers for the dataloader.")
    args = parser.parse_args()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")

    # Data transformations
    data_transforms = {
        'train': transforms.Compose([
            transforms.RandomResizedCrop(224),
            transforms.RandomHorizontalFlip(),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
        'val': transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
    }

    # Create datasets and dataloaders
    print("Loading datasets...")
    train_dataset = CarDataset(csv_file=args.train_csv, transform=data_transforms['train'])
    valid_dataset = CarDataset(csv_file=args.valid_csv, transform=data_transforms['val'])
    
    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True, num_workers=args.num_workers)
    valid_loader = DataLoader(valid_dataset, batch_size=args.batch_size, shuffle=False, num_workers=args.num_workers)
    
    num_classes = len(train_dataset.label_to_idx)
    print(f"Number of classes: {num_classes}")

    # Load pre-trained model and modify the final layer
    print("Loading pre-trained EfficientNet-B0 model...")
    model = models.efficientnet_b0(weights=models.EfficientNet_B0_Weights.DEFAULT)
    num_ftrs = model.classifier[1].in_features
    model.classifier[1] = nn.Linear(num_ftrs, num_classes)
    
    model = model.to(device)

    # Loss function and optimizer
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=args.lr)

    # Training loop
    best_acc = 0.0
    model_dir = Path(args.model_dir)
    model_dir.mkdir(parents=True, exist_ok=True)

    for epoch in range(args.epochs):
        print(f"\nEpoch {epoch+1}/{args.epochs}")
        print("-" * 10)
        
        train_loss, train_acc = train_model(model, train_loader, criterion, optimizer, device)
        print(f"Training Loss: {train_loss:.4f}, Training Acc: {train_acc:.4f}")
        
        val_loss, val_acc = validate_model(model, valid_loader, criterion, device)
        print(f"Validation Loss: {val_loss:.4f}, Validation Acc: {val_acc:.4f}")
        
        # Save the best model
        if val_acc > best_acc:
            best_acc = val_acc
            best_model_path = model_dir / 'car_classifier_best.pt'
            torch.save(model.state_dict(), best_model_path)
            print(f"Best model saved to {best_model_path}")

    print("\nTraining complete.")
    print(f"Best Validation Accuracy: {best_acc:.4f}")

if __name__ == "__main__":
    main()
