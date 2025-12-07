
import argparse
import cv2
from ultralytics import YOLO

def process_video(model_path, video_path, output_path):
    """
    Processes a video using a YOLO model for object detection.

    Args:
        model_path (str): Path to the YOLO model file.
        video_path (str): Path to the input video file.
        output_path (str): Path to save the output video file.
    """
    # Load the YOLO model
    model = YOLO(model_path)

    # Open the input video
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"Error: Could not open video {video_path}")
        return

    # Get video properties
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS)

    # Define the codec and create VideoWriter object
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

    total_detections = 0
    frame_count = 0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        frame_count += 1

        # Run YOLO detection
        results = model(frame)
        
        # Count detections
        detections_in_frame = len(results[0].boxes)
        total_detections += detections_in_frame
        # print(f"Frame {frame_count}: {detections_in_frame} detections") # Optional: Comment out for less noise

        # Get the annotated frame
        annotated_frame = results[0].plot()

        # Write the frame to the output video
        out.write(annotated_frame)

    # Release everything when job is finished
    cap.release()
    out.release()
    cv2.destroyAllWindows()
    
    avg_detections = total_detections / frame_count if frame_count > 0 else 0
    print(f"Processed video saved to {output_path}")
    print(f"Total Frames: {frame_count}")
    print(f"Average Detections per Frame: {avg_detections:.2f}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process a video with a YOLO model.")
    parser.add_argument("--model", required=True, help="Path to the YOLO model file.")
    parser.add_argument("--video", required=True, help="Path to the input video file.")
    parser.add_argument("--output", required=True, help="Path to save the output video file.")
    args = parser.parse_args()

    process_video(args.model, args.video, args.output)
