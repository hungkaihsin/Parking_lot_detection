from ultralytics import YOLO
import cv2
import numpy as np
from shapely.geometry import Point, Polygon
from . import models
import torch
from torchvision import models as vision_models, transforms
from PIL import Image
import os
from shapely import wkt
import logging
import time

# Get the logger
app_logger = logging.getLogger('recommender_api')

# --- Vehicle Size Classifier ---

# NOTE: This assumes the model file is present at the specified path inside the container.
MODEL_PATH = "/app/models/car_classifier_best.pt"
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
    print(f"Warning: Size classifier model not found at {MODEL_PATH}. Size detection will be disabled.")


def classify_vehicle_size(image_crop_pil: Image.Image) -> str:
    """
    Uses the trained classifier to predict the size of the vehicle from a cropped image.
    """
    if 'size_classifier' not in globals() or size_classifier is None:
        return "unknown"
        
    image_tensor = size_transform(image_crop_pil).unsqueeze(0).to(device)
    
    with torch.no_grad():
        outputs = size_classifier(image_tensor)
        _, preds = torch.max(outputs, 1)
        predicted_idx = preds.item()
        
    return IDX_TO_LABEL.get(predicted_idx, "unknown")

# --- End Vehicle Size Classifier ---


def get_occupied_stalls(model: YOLO, image_bytes: bytes, stalls: list[models.Stall], conf: float = 0.25, iou: float = 0.4) -> dict[str, dict]:
    """
    Detects occupied stalls and classifies vehicle size.

    Args:
        model: The loaded YOLO model.
        image_bytes: The image content as bytes.
        stalls: A list of Stall objects from the database.
        conf: Confidence threshold for object detection.
        iou: IoU threshold for non-maximum suppression.

    Returns:
        A dictionary where keys are occupied stall IDs and values are dicts
        containing vehicle size info. e.g., {'A1': {'size': 'midsize'}}
    """
    start_time = time.time()

    # 1. Decode the image
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    H, W, _ = img.shape # Original image dimensions
    decode_time = (time.time() - start_time) * 1000

    # 2. Run detection on the image
    yolo_start_time = time.time()
    results = model(img, conf=conf, iou=iou, imgsz=640) # Pass conf and iou, and specify imgsz
    yolo_inference_time = (time.time() - yolo_start_time) * 1000

    # 3. Pre-parse stall polygons to avoid repeated WKT loading
    preparse_start_time = time.time()
    precomputed_stalls = [(stall.id, wkt.loads(stall.geom_wkt)) for stall in stalls]
    preparse_time = (time.time() - preparse_start_time) * 1000

    # 4. Determine stall occupancy and vehicle size
    postprocess_start_time = time.time()
    occupancy_data = {}
    for r in results:
        # Get original image dimensions (YOLO results object already handles scaling)
        orig_H, orig_W = r.orig_shape
        
        for box in r.boxes:
            class_id = int(box.cls[0])
            class_name = model.names[class_id]
            app_logger.info(f"Raw detection: class_name={class_name}, box.xyxy[0]={box.xyxy[0]}")
            if class_name == 'occupied': # Assuming 'occupied' is the class for occupied vehicles
                x1_orig, y1_orig, x2_orig, y2_orig = [float(c) for c in box.xyxy[0]]
                
                # Ensure coordinates are within original image bounds
                x1_orig = max(0, int(x1_orig))
                y1_orig = max(0, int(y1_orig))
                x2_orig = min(orig_W, int(x2_orig))
                y2_orig = min(orig_H, int(y2_orig))

                car_crop_bgr = img[y1_orig:y2_orig, x1_orig:x2_orig]
                
                # Only classify if crop is valid (not empty)
                if car_crop_bgr.shape[0] > 0 and car_crop_bgr.shape[1] > 0:
                    car_crop_pil = Image.fromarray(cv2.cvtColor(car_crop_bgr, cv2.COLOR_BGR2RGB))
                    size_class = classify_vehicle_size(car_crop_pil)
                else:
                    size_class = "unknown"
                # --- End New ---

                # Calculate center of the detection box in the ORIGINAL image space
                center_x_orig = (x1_orig + x2_orig) / 2
                center_y_orig = (y1_orig + y2_orig) / 2
                detection_point = Point(center_x_orig, center_y_orig)
                app_logger.info(f"Processing detection point: {detection_point.wkt}")

                for stall_id, stall_polygon in precomputed_stalls:
                    app_logger.info(f"Checking stall {stall_id} with polygon: {stall_polygon.wkt}")
                    if stall_polygon.contains(detection_point):
                        app_logger.info(f"Detection point {detection_point.wkt} IS contained in stall {stall_id}")
                        occupancy_data[stall_id] = {"size": size_class}
                        break
                    else:
                        app_logger.info(f"Detection point {detection_point.wkt} NOT contained in stall {stall_id}")
    postprocess_time = (time.time() - postprocess_start_time) * 1000
    total_time = (time.time() - start_time) * 1000


    app_logger.info(f"get_occupied_stalls timing: Decode={decode_time:.2f}ms, YOLO Inference={yolo_inference_time:.2f}ms, Preparse Stalls={preparse_time:.2f}ms, Postprocess={postprocess_time:.2f}ms, Total={total_time:.2f}ms")
    app_logger.info(f"Final occupancy data: {occupancy_data}")
    
    return occupancy_data

