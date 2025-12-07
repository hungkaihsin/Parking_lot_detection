from ultralytics import YOLO
import cv2
import os
import json
import numpy as np
from shapely.geometry import Point, Polygon

def load_stalls_from_geojson(geojson_path):
    """
    Loads stall polygons and their neighbors from a GeoJSON file.
    """
    with open(geojson_path, 'r') as f:
        data = json.load(f)
    
    stalls = []
    for feature in data['features']:
        try:
            coordinates = feature['geometry']['coordinates'][0]
            if not all(isinstance(p, list) and len(p) == 2 and all(isinstance(c, (int, float)) for c in p) for p in coordinates):
                print(f"Skipping invalid feature due to malformed coordinates: {feature['properties']['id']}")
                continue
            polygon = Polygon(coordinates)
            stalls.append({
                "id": feature['properties']['id'],
                "polygon": polygon,
                "neighbors": feature['properties']['neighbors'],
                "width_class": feature['properties']['width_class'],
                "dist_to_entrance": feature['properties']['dist_to_entrance']
            })
        except (TypeError, IndexError) as e:
            print(f"Skipping invalid feature due to error: {e}")
    return stalls

def create_ignore_mask(image_shape, polygons):
    """
    Creates an ignore mask from a list of polygons.
    """
    mask = np.zeros(image_shape[:2], dtype=np.uint8)
    for polygon in polygons:
        pts = np.array(polygon.exterior.coords, dtype=np.int32)
        pts = pts.reshape((-1, 1, 2))
        cv2.fillPoly(mask, [pts], 255)
    return mask

def find_best_stall(stalls, stall_occupancy, vehicle_size=1):
    """
    Finds the best available parking stall based on neighbor occupancy, vehicle size, and distance to entrance.
    """
    best_stall = None
    max_free_neighbors = -1
    min_dist_to_entrance = float('inf')

    for stall in stalls:
        if stall_occupancy[stall['id']] == 'free' and stall['width_class'] >= vehicle_size:
            free_neighbors = 0
            for neighbor_id in stall['neighbors']:
                if stall_occupancy.get(neighbor_id) == 'free':
                    free_neighbors += 1
            
            if free_neighbors > max_free_neighbors:
                max_free_neighbors = free_neighbors
                min_dist_to_entrance = stall['dist_to_entrance']
                best_stall = stall
            elif free_neighbors == max_free_neighbors:
                if stall['dist_to_entrance'] is not None and min_dist_to_entrance is not None and stall['dist_to_entrance'] < min_dist_to_entrance:
                    min_dist_to_entrance = stall['dist_to_entrance']
                    best_stall = stall

    return best_stall

def detect_stalls(image_path, geojson_path, output_path="detection_result.jpg", vehicle_size=1):
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

    # Load stalls and create ignore mask
    try:
        stalls = load_stalls_from_geojson(geojson_path)
        ignore_mask = create_ignore_mask(img.shape, [s['polygon'] for s in stalls])
    except Exception as e:
        print(f"Error creating ignore mask: {e}")
        return

    # Apply the ignore mask to the image
    img[ignore_mask == 0] = 0

    # Run detection on the image
    try:
        results = model(img)
    except Exception as e:
        print(f"Error running detection: {e}")
        return

    # Determine stall occupancy
    stall_occupancy = {s['id']: 'free' for s in stalls}
    for r in results:
        for box in r.boxes:
            class_id = int(box.cls[0])
            class_name = model.names[class_id]
            if class_name == 'car':
                x1, y1, x2, y2 = [int(c) for c in box.xyxy[0]]
                center_x = (x1 + x2) / 2
                center_y = (y1 + y2) / 2
                point = Point(center_x, center_y)
                for stall in stalls:
                    if stall['polygon'].contains(point):
                        stall_occupancy[stall['id']] = 'occupied'
                        break

    # Find the best stall
    best_stall = find_best_stall(stalls, stall_occupancy, vehicle_size)
    if best_stall:
        print(f"Best stall found for vehicle size {vehicle_size}: {best_stall['id']} (Distance: {best_stall['dist_to_entrance']})")

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
    import argparse

    parser = argparse.ArgumentParser(description="Detect parking stalls in an image.")
    parser.add_argument("--image", type=str, default="/app/data/parking_lot/parking lot.v3i.yolov8/train/images/-2023-05-03-093043_png_jpg.rf.78bc02b53ea9338893e289a66e76f0b9.jpg", help="Path to the input image.")
    parser.add_argument("--geojson", type=str, default="/app/data/lot_a_layout.geojson", help="Path to the GeoJSON file.")
    parser.add_argument("--output", type=str, default="/app/output/detection_result.jpg", help="Path to save the output image.")
    parser.add_argument("--vehicle-size", type=int, default=1, help="Vehicle size to consider for finding the best stall.")
    args = parser.parse_args()

    detect_stalls(args.image, args.geojson, args.output, args.vehicle_size)
