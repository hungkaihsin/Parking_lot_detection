#!/usr/bin/env python3
import argparse
import os
import sys
import time
from pathlib import Path
import cv2
import torch
import datetime
from shapely.geometry import Polygon, box
from shapely import wkt
from ultralytics import YOLO

# Add the project root to the Python path
sys.path.append(str(Path(__file__).parent.parent))

from app.db import get_db
from app.models import Stall, SpotStatus, Run

def get_video_files(path):
    """Gets a list of video files from a given path."""
    p = Path(path)
    if p.is_file():
        return [p]
    elif p.is_dir():
        return [f for f in p.glob("**/*") if f.suffix.lower() in (".mp4", ".avi", ".mov")]
    return []

def process_video(db_session, video_path: Path, run_id: str, stalls: dict):
    """
    Processes a video to detect parking occupancy.
    """
    # 1. Initialize model
    model = YOLO("models/parking_lot.pt")  # Using a default model

    # Get the last known status for each stall to minimize DB queries
    last_statuses = {}
    for stall_id in stalls.keys():
        status = db_session.query(SpotStatus).filter_by(spot_id=stall_id).order_by(SpotStatus.ts_ms.desc()).first()
        last_statuses[stall_id] = status.state if status else None

    # 2. Video capture
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        print(f"Error opening video file: {video_path}")
        return

    fps = cap.get(cv2.CAP_PROP_FPS)
    # Process about 1 frame per second
    frame_skip = int(fps) if fps and fps > 1 else 1

    frame_count = 0
    processed_frame_count = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Skip frames to improve performance
        if frame_count % frame_skip != 0:
            frame_count += 1
            continue

        frame_count += 1
        processed_frame_count += 1
        ts_ms = cap.get(cv2.CAP_PROP_POS_MSEC)

        start_time = time.time()

        # 3. Run detection
        results = model.predict(source=frame, save=False, verbose=False)
        detections = results[0].boxes.xyxy.cpu().numpy()

        # Manually save the frame with a unique name
        annotated_frame = results[0].plot()

        # Create a directory for the current run
        save_dir = Path("runs/detect") / run_id
        save_dir.mkdir(parents=True, exist_ok=True)

        # Create a unique filename
        filename = f"frame_{processed_frame_count:04d}.jpg"
        save_path = save_dir / filename
        
        cv2.imwrite(str(save_path), annotated_frame)
        
        # 4. Match detections to stalls and update status
        new_statuses_to_add = []
        for stall_id, stall_geom in stalls.items():
            is_occupied = False
            for det in detections:
                det_box = box(det[0], det[1], det[2], det[3])
                # Ensure geometries are valid to prevent TopologyException
                valid_stall_geom = stall_geom.buffer(0)
                valid_det_box = det_box.buffer(0)

                if valid_stall_geom.intersects(valid_det_box):
                    intersection_area = valid_stall_geom.intersection(valid_det_box).area
                    union_area = valid_stall_geom.union(valid_det_box).area
                    if union_area > 0:
                        iou = intersection_area / union_area
                        if iou > 0.5:
                            is_occupied = True
                            break
            
            current_state = "TAKEN" if is_occupied else "FREE"

            # 5. Check previous state and update if changed
            if last_statuses.get(stall_id) != current_state:
                new_status = SpotStatus(
                    run_id=run_id,
                    ts_ms=int(ts_ms),
                    spot_id=stall_id,
                    state=current_state
                )
                new_statuses_to_add.append(new_status)
                last_statuses[stall_id] = current_state
        
        # 6. Batch update to the database
        if new_statuses_to_add:
            db_session.add_all(new_statuses_to_add)
            db_session.commit()
        
        end_time = time.time()
        duration = end_time - start_time
        print(f"Processed frame {processed_frame_count}: took {duration:.2f} seconds")

    cap.release()

def main():
    """Main function to run the occupancy service."""
    parser = argparse.ArgumentParser(description="Parking Occupancy Detection Service")
    parser.add_argument("--video", required=True, help="Path to the video file or directory of videos.")
    parser.add_argument("--run-id", help="A unique ID for this processing run.")
    args = parser.parse_args()

    # 1. Get video files
    video_files = get_video_files(args.video)
    if not video_files:
        print(f"No video files found in {args.video}")
        return

    # 2. Initialize database and process videos
    db_session = next(get_db())
    try:
        stalls = {s.id: wkt.loads(s.geom_wkt) for s in db_session.query(Stall).all()}

        if not stalls:
            print("No parking stalls found in the database.")
            return

        # 3. Process each video
        for video_path in video_files:
            run_id = args.run_id or f"run_{video_path.stem}_{os.urandom(4).hex()}"
            print(f"Processing video: {video_path} with run_id: {run_id}")

            # Create a new run entry
            new_run = Run(run_id=run_id, lot_id="LotA", video_path=str(video_path), started_at=datetime.datetime.now(datetime.timezone.utc))
            db_session.add(new_run)
            db_session.commit()

            process_video(db_session, video_path, run_id, stalls)

            # Update run entry with end time
            run_to_update = db_session.query(Run).filter_by(run_id=run_id).first()
            if run_to_update:
                run_to_update.ended_at = datetime.datetime.now(datetime.timezone.utc)
                db_session.commit()
    finally:
        db_session.close()

if __name__ == "__main__":
    main()