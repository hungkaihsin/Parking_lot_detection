import argparse
from ultralytics import YOLO

def evaluate_model(model_path, data_yaml_path, conf=0.001, iou=0.6):
    """
    Evaluates a YOLO model on a test set.
    """
    # Load the YOLO model
    try:
        model = YOLO(model_path)
    except Exception as e:
        print(f"Error loading model: {e}")
        return

    # Run evaluation
    try:
        metrics = model.val(data=data_yaml_path, split='test', conf=conf, iou=iou)
        return metrics
    except Exception as e:
        print(f"Error during evaluation: {e}")
        return None

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Evaluate a YOLO model.")
    parser.add_argument("--model_path", type=str, default="/app/models/parking_lot.pt", help="Path to the YOLO model.")
    parser.add_argument("--data_yaml_path", type=str, default="/app/data/parking_lot/parking lot.v3i.yolov8/data.yaml", help="Path to the data YAML file.")
    parser.add_argument("--conf", type=float, default=0.001, help="Confidence threshold for evaluation.")
    parser.add_argument("--iou", type=float, default=0.6, help="IOU threshold for evaluation.")
    args = parser.parse_args()

    metrics = evaluate_model(args.model_path, args.data_yaml_path, args.conf, args.iou)

    if metrics:
        print("Evaluation metrics:")
        print(f"  mAP50-95: {metrics.box.map}")
        print(f"  mAP50: {metrics.box.map50}")
        print(f"  mAP75: {metrics.box.map75}")
        # Note: metrics.box.p and metrics.box.r are lists, typically for different classes.
        # Assuming single-class or average precision/recall is at index 0.
        precision = metrics.box.p[0] if metrics.box.p.size > 0 else 0
        recall = metrics.box.r[0] if metrics.box.r.size > 0 else 0
        f1_score = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
        print(f"  Precision: {precision}")
        print(f"  Recall: {recall}")
        print(f"  F1-score: {f1_score}")
