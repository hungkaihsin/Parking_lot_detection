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

        print("\nClass-wise metrics:")
        f1_scores = []
        class_stats = []

        for i, name in sorted(metrics.names.items()):
            precision = metrics.box.p[i]
            recall = metrics.box.r[i]
            f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
            f1_scores.append(f1)
            class_stats.append({'name': name, 'p': precision, 'r': recall, 'f1': f1})
            
            print(f"  Class '{name}':")
            print(f"    Precision: {precision:.4f}")
            print(f"    Recall:    {recall:.4f}")
            print(f"    F1-score:  {f1:.4f}")

        # Calculate and print overall metrics for "all" classes
        # This is the mean of the per-class metrics, which matches the 'all' line in the user's output
        if len(class_stats) > 0:
            overall_p = sum(c['p'] for c in class_stats) / len(class_stats)
            overall_r = sum(c['r'] for c in class_stats) / len(class_stats)
            
            # F1 of averages is not average of F1s. Let's recalculate.
            overall_f1_recalculated = 2 * (overall_p * overall_r) / (overall_p + overall_r) if (overall_p + overall_r) > 0 else 0


            print("\n  Overall (mean of classes):")
            print(f"    Precision: {overall_p:.4f}")
            print(f"    Recall:    {overall_r:.4f}")
            print(f"    F1-score:  {overall_f1_recalculated:.4f}")
