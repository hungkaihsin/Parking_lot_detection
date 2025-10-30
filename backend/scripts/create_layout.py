import cv2
import argparse
import json
import uuid
import numpy as np
from pathlib import Path

# Global variables
current_polygon_points = []
all_polygons = [] # Will store dicts: {'points': [], 'is_ev': bool, 'is_ada': bool}

def mouse_callback(event, x, y, flags, param):
    """Mouse callback function to handle drawing polygons."""
    global current_polygon_points

    if event == cv2.EVENT_LBUTTONDOWN:
        current_polygon_points.append((x, y))
        print(f"Added point: ({x}, {y})")

def main():
    parser = argparse.ArgumentParser(description="Stall Layout Editor")
    parser.add_argument("--video", required=True, help="Path to the video file.")
    args = parser.parse_args()

    video_path = Path(args.video)
    if not video_path.is_file():
        print(f"Error: Video file not found at {video_path}")
        return

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        print(f"Error: Could not open video file.")
        return

    ret, frame = cap.read()
    if not ret:
        print("Error: Could not read the first frame of the video.")
        cap.release()
        return

    window_name = "Stall Layout Editor"
    cv2.namedWindow(window_name)
    cv2.setMouseCallback(window_name, mouse_callback)
    
    print("--- Stall Layout Editor ---")
    print("Left-click to add points to a polygon.")
    print("Press 'n' to finish the current stall.")
    print("Press 'c' to clear the current stall's points.")
    print("Press 's' to save the layout.")
    print("Press 'q' to quit.")
    print("---------------------------")

    while True:
        display_frame = frame.copy()

        # Draw completed polygons
        if all_polygons:
            for poly_data in all_polygons:
                pts = np.array(poly_data['points'], np.int32).reshape((-1, 1, 2))
                # Use different colors for different types
                color = (0, 0, 255) # Red for normal
                if poly_data['is_ev'] and poly_data['is_ada']:
                    color = (255, 0, 255) # Magenta for EV+ADA
                elif poly_data['is_ev']:
                    color = (255, 255, 0) # Cyan for EV
                elif poly_data['is_ada']:
                    color = (0, 165, 255) # Orange for ADA
                cv2.polylines(display_frame, [pts], isClosed=True, color=color, thickness=2)

                # Calculate centroid for text placement
                M = cv2.moments(pts)
                if M['m00'] != 0:
                    cx = int(M['m10'] / M['m00'])
                    cy = int(M['m01'] / M['m00'])
                else:
                    cx, cy = pts[0][0][0], pts[0][0][1] # Fallback to first point if moment is zero

                # Display badges/icons
                text_offset_y = 0
                if poly_data['is_ev']:
                    cv2.putText(display_frame, "EV", (cx, cy + text_offset_y), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
                    text_offset_y += 15
                if poly_data['is_ada']:
                    cv2.putText(display_frame, "ADA", (cx, cy + text_offset_y), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
                    text_offset_y += 15
                if poly_data['is_buffered']:
                    cv2.putText(display_frame, "BUF", (cx, cy + text_offset_y), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
                    text_offset_y += 15
                
                width_class_map_reverse = {
                    0: "Compact",
                    1: "Midsize",
                    2: "Full",
                    3: "SUV",
                    4: "Truck"
                }
                width_class_text = width_class_map_reverse.get(poly_data['width_class'], "Unknown")
                cv2.putText(display_frame, width_class_text, (cx, cy + text_offset_y), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

        # Draw the current polygon being drawn
        if current_polygon_points:
            for point in current_polygon_points:
                cv2.circle(display_frame, point, 4, (0, 255, 0), -1)
            if len(current_polygon_points) > 1:
                pts = np.array(current_polygon_points, np.int32).reshape((-1, 1, 2))
                cv2.polylines(display_frame, [pts], isClosed=False, color=(0, 255, 0), thickness=2)

        cv2.imshow(window_name, display_frame)
        
        key = cv2.waitKey(20) & 0xFF

        if key == ord('q'):
            break
        elif key == ord('c'):
            current_polygon_points.clear()
            print("Cleared current polygon.")
        elif key == ord('n'):
            if len(current_polygon_points) > 2:
                # Prompt for stall type in the terminal
                is_ev_input = input("Is this an EV spot? (y/n): ").lower()
                is_ada_input = input("Is this an ADA (disabled) spot? (y/n): ").lower()
                is_buffered_input = input("Is this a buffered spot? (y/n): ").lower()
                width_class_input = input("Enter width class (Compact, Midsize, Full, SUV, Truck): ").lower()
                
                is_ev = is_ev_input == 'y'
                is_ada = is_ada_input == 'y'
                is_buffered = is_buffered_input == 'y'

                width_class_map = {
                    "compact": 0,
                    "midsize": 1,
                    "full": 2,
                    "suv": 3,
                    "truck": 4
                }
                width_class = width_class_map.get(width_class_input, 1) # Default to Midsize

                all_polygons.append({
                    "points": list(current_polygon_points),
                    "is_ev": is_ev,
                    "is_ada": is_ada,
                    "is_buffered": is_buffered,
                    "width_class": width_class
                })
                print(f"Completed polygon. EV: {is_ev}, ADA: {is_ada}, Buffered: {is_buffered}, Width Class: {width_class_input} ({width_class})")
                current_polygon_points.clear()
            else:
                print("A polygon must have at least 3 points.")
        elif key == ord('s'):
            if not all_polygons:
                print("No polygons to save.")
                continue

            feedback_frame = display_frame.copy()
            cv2.putText(feedback_frame, "Saving... Check terminal.", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
            cv2.imshow(window_name, feedback_frame)
            cv2.waitKey(1)

            output_filename = input("Enter the output filename (e.g., lot_layout.geojson): ")
            if not output_filename:
                print("Save cancelled.")
                continue
            if not output_filename.endswith(".geojson"):
                output_filename += ".geojson"

            feature_collection = {
                "type": "FeatureCollection",
                "features": []
            }

            for poly_data in all_polygons:
                polygon_points = poly_data['points']
                stall_id = str(uuid.uuid4())
                
                if polygon_points[0] != polygon_points[-1]:
                    polygon_points.append(polygon_points[0])

                feature = {
                    "type": "Feature",
                    "properties": {
                        "id": stall_id,
                        "is_ev": poly_data['is_ev'],
                        "is_ada": poly_data['is_ada'],
                        "is_buffered": poly_data['is_buffered'],
                        "width_class": poly_data['width_class']
                    },
                    "geometry": {
                        "type": "Polygon",
                        "coordinates": [polygon_points]
                    }
                }
                feature_collection["features"].append(feature)

            try:
                save_path = Path("data") / output_filename
                with open(save_path, "w") as f:
                    json.dump(feature_collection, f, indent=2)
                print(f"Successfully saved layout to {save_path}")

                success_frame = display_frame.copy()
                cv2.putText(success_frame, f"Saved!", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                cv2.imshow(window_name, success_frame)
                cv2.waitKey(2000)

            except Exception as e:
                print(f"Error saving file: {e}")

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()