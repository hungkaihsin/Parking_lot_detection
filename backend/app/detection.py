
from ultralytics import YOLO
import cv2
import numpy as np
from shapely.geometry import Point, Polygon
from . import models

def get_occupied_stalls(model: YOLO, image_bytes: bytes, stalls: list[models.Stall]) -> list[str]:
    """
    Detects occupied stalls in an image.

    Args:
        model: The loaded YOLO model.
        image_bytes: The image content as bytes.
        stalls: A list of Stall objects from the database.

    Returns:
        A list of stall IDs that are occupied.
    """
    # 1. Decode the image
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    # 2. Run detection on the image
    results = model(img)

    # 3. Determine stall occupancy
    occupied_stall_ids = set()
    for r in results:
        for box in r.boxes:
            class_id = int(box.cls[0])
            class_name = model.names[class_id]
            if class_name == 'car':
                x1, y1, x2, y2 = [int(c) for c in box.xyxy[0]]
                center_x = (x1 + x2) / 2
                center_y = (y1 + y2) / 2
                detection_point = Point(center_x, center_y)

                for stall in stalls:
                    # Assuming stall.geom_wkt is a WKT representation of the polygon
                    # We need to parse it into a Shapely Polygon
                    from shapely import wkt
                    stall_polygon = wkt.loads(stall.geom_wkt)
                    if stall_polygon.contains(detection_point):
                        occupied_stall_ids.add(stall.id)
                        break
    
    return list(occupied_stall_ids)
