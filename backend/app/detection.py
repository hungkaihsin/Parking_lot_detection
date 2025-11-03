
from ultralytics import YOLO
import cv2
import numpy as np
from shapely.geometry import Point, Polygon
from . import models
import torch
from torchvision import models as vision_models, transforms
from PIL import Image
import os

# --- Vehicle Size Classifier ---

# 1. Load the trained model
# NOTE: This assumes the model file is present at the specified path inside the container.
MODEL_PATH = "/app/models/size_classifier/car_classifier_best.pt"
NUM_CLASSES = 5 # compact, midsize, full, suv, truck

# Check if the model file exists before loading
if os.path.exists(MODEL_PATH):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    
    # Re-create the model architecture
    size_classifier = vision_models.efficientnet_b0(weights=None)
    num_ftrs = size_classifier.classifier[1].in_features
    size_classifier.classifier[1] = torch.nn.Linear(num_ftrs, NUM_CLASSES)
    
    # Load the trained weights
    size_classifier.load_state_dict(torch.load(MODEL_PATH, map_location=device))
    size_classifier.to(device)
    size_classifier.eval()

    # 2. Define the transformations (must be the same as validation transforms)
    size_transform = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    # 3. Define the mapping from index to label
    # This is based on the order of labels encountered during training.
    # We assume: 0: compact, 1: midsize, 2: full, 3: suv, 4: truck
    # A more robust solution would save this mapping alongside the model.
    IDX_TO_LABEL = {0: 'compact', 1: 'midsize', 2: 'full', 3: 'suv', 4: 'truck'}

else:
    size_classifier = None
    print(f"Warning: Size classifier model not found at {MODEL_PATH}. Size detection will be disabled.")


def classify_vehicle_size(image_crop_pil: Image.Image) -> str:
    """
    Uses the trained classifier to predict the size of the vehicle from a cropped image.
    """
    if size_classifier is None:
        return "unknown"
        
    image_tensor = size_transform(image_crop_pil).unsqueeze(0).to(device)
    
    with torch.no_grad():
        outputs = size_classifier(image_tensor)
        _, preds = torch.max(outputs, 1)
        predicted_idx = preds.item()
        
    return IDX_TO_LABEL.get(predicted_idx, "unknown")

# --- End Vehicle Size Classifier ---


def get_occupied_stalls(model: YOLO, image_bytes: bytes, stalls: list[models.Stall]) -> dict[str, dict]:
    """
    Detects occupied stalls and classifies vehicle size.

    Args:
        model: The loaded YOLO model.
        image_bytes: The image content as bytes.
        stalls: A list of Stall objects from the database.

    Returns:
        A dictionary where keys are occupied stall IDs and values are dicts
        containing vehicle size info. e.g., {'A1': {'size': 'midsize'}}
    """
    # 1. Decode the image
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    # 2. Run detection on the image
    results = model(img)

    # 3. Determine stall occupancy and vehicle size
    occupancy_data = {}
    for r in results:
        for box in r.boxes:
            class_id = int(box.cls[0])
            class_name = model.names[class_id]
            if class_name == 'car':
                x1, y1, x2, y2 = [int(c) for c in box.xyxy[0]]
                
                # --- New: Use Classifier for Size ---
                # Crop the detected car
                car_crop_bgr = img[y1:y2, x1:x2]
                # Convert to PIL Image (RGB)
                car_crop_pil = Image.fromarray(cv2.cvtColor(car_crop_bgr, cv2.COLOR_BGR2RGB))
                
                # Classify the size using the trained model
                size_class = classify_vehicle_size(car_crop_pil)
                # --- End New ---

                center_x = (x1 + x2) / 2
                center_y = (y1 + y2) / 2
                detection_point = Point(center_x, center_y)

                for stall in stalls:
                    from shapely import wkt
                    stall_polygon = wkt.loads(stall.geom_wkt)
                    if stall_polygon.contains(detection_point):
                        # Store size information for the occupied stall
                        occupancy_data[stall.id] = {"size": size_class}
                        break
    
    return occupancy_data
