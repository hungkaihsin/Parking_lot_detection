from ultralytics import YOLO

def evaluate_model(model_path, data_yaml_path):
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
        metrics = model.val(data=data_yaml_path, split='test')
        return metrics
    except Exception as e:
        print(f"Error during evaluation: {e}")
        return None

if __name__ == "__main__":
    model_path = "/app/models/parking_lot.pt"
    data_yaml_path = "/app/data/parking_lot/parking lot.v2i.yolov11/data.yaml"
    
    metrics = evaluate_model(model_path, data_yaml_path)
    
    if metrics:
        print("Evaluation metrics:")
        print(f"  mAP50-95: {metrics.box.map}")
        print(f"  mAP50: {metrics.box.map50}")
        print(f"  mAP75: {metrics.box.map75}")
        print(f"  Precision: {metrics.box.p[0]}")
        print(f"  Recall: {metrics.box.r[0]}")
        print(f"  F1-score: {2 * (metrics.box.p[0] * metrics.box.r[0]) / (metrics.box.p[0] + metrics.box.r[0])}")
