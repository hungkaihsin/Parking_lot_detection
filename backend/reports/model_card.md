# Model Card: Parking Lot Occupancy Detector

This model card provides information about the YOLOv8 object detection model used for identifying parking space occupancy.

## 1. Model Details

- **Model:** `parking_lot.pt` (also referred to as `yolo_car_best.pt`)
- **Architecture:** YOLOv8
- **Task:** Object Detection
- **Framework:** PyTorch (via Ultralytics)
- **Classes:** `empty`, `occupied`

## 2. Intended Use

This model is intended to be used for detecting the occupancy state (either 'empty' or 'occupied') of parking stalls from a fixed-camera image of a parking lot. It is designed to be the first step in a system that monitors parking availability.

## 3. Training Data

The model was trained on a dataset sourced from Roboflow.

- **Dataset:** [Parking Lot Dataset (v10)](https://universe.roboflow.com/smoking-detection-2debl/parking-lot-j4ojc-dehsm/dataset/10)
- **Classes:** The dataset consists of images with bounding boxes for two classes: `empty` and `occupied`.
- **License:** The dataset is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

## 4. Evaluation Metrics

The model was evaluated on a test set of 254 images containing 7912 instances.

### Overall Performance

| Metric   | Value  |
|----------|--------|
| mAP50-95 | 0.897  |
| mAP50    | 0.990  |
| mAP75    | 0.963  |
| Precision| 0.978  |
| Recall   | 0.979  |

### Performance by Class

| Class    | Precision | Recall | F1-Score |
|----------|-----------|--------|----------|
| `empty`  | 0.973     | 0.982  | 0.978    |
| `occupied`| 0.984     | 0.977  | 0.980    |

## 5. Limitations

- **Lighting Conditions:** The primary model (`parking_lot.pt`) is trained on daytime images. Its performance is expected to be significantly lower in low-light, nighttime, or adverse weather conditions (e.g., heavy rain, fog, snow).
- **Generalization:** The model was trained on a specific parking lot. Performance on other lots with different camera angles, layouts, or lighting is not guaranteed and may be poor without re-training or fine-tuning.
- **Occlusion:** Performance may degrade when vehicles are partially obscured by other vehicles, pedestrians, or objects.

## 6. Privacy Considerations

- **Personally Identifiable Information (PII):** The source images used for training and inference may contain PII, such as license plates on vehicles or recognizable individuals walking in the lot.
- **Mitigation:** While the model itself does not store any PII, any system implementing this model should consider implementing privacy-preserving measures, such as blurring or masking license plates and faces from the input images before processing or storage.
