
from ultralytics import YOLO
import cv2
import os

def detect_stalls(image_path, output_path="detection_result.jpg"):
    """
    Detects parking stalls in an image, draws bounding boxes, and saves the result.
    """
    # Create output directory if it doesn't exist
    output_dir = os.path.dirname(output_path)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Load the YOLO model
    try:
        model = YOLO("/app/models/parking_lot.pt")
    except Exception as e:
        print(f"Error loading model: {e}")
        return

    # Read the image
    try:
        img = cv2.imread(image_path)
        if img is None:
            print(f"Error: Could not read image at {image_path}")
            return
    except Exception as e:
        print(f"Error reading image: {e}")
        return

    # Run detection on the image
    try:
        results = model(image_path)
    except Exception as e:
        print(f"Error running detection: {e}")
        return

    # Draw bounding boxes and labels
    for r in results:
        print("Detections for image:", image_path)
        for box in r.boxes:
            class_id = int(box.cls[0])
            class_name = model.names[class_id]
            confidence = float(box.conf[0])
            x1, y1, x2, y2 = [int(c) for c in box.xyxy[0]]
            
            # Draw rectangle
            color = (0, 255, 0) if class_name == 'free' else (0, 0, 255)
            cv2.rectangle(img, (x1, y1), (x2, y2), color, 2)
            
            # Draw label
            label = f"{class_name}: {confidence:.2f}"
            cv2.putText(img, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)
            
            print(f"  - Class: {class_name}, Confidence: {confidence:.2f}, BBox: ({x1}, {y1}, {x2}, {y2})")

    # Save the result
    try:
        cv2.imwrite(output_path, img)
        print(f"Detection result saved to {output_path}")
    except Exception as e:
        print(f"Error saving image: {e}")

if __name__ == "__main__":
    # Path to a sample image from your dataset
    sample_image = "/app/data/parking_lot/parking lot.v2i.yolov11/train/images/-2023-05-03-093043_png_jpg.rf.78bc02b53ea9338893e289a66e76f0b9.jpg"
    output_image = "/app/output/detection_result.jpg"
    detect_stalls(sample_image, output_image)
