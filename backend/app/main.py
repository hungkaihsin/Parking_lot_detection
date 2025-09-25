from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from dotenv import load_dotenv
from ultralytics import YOLO
import torch

from .db import get_db
from . import models

# Load .env (ensures DATABASE_URL is available)
load_dotenv()
app = FastAPI(title="Parking Lot Recommender API")

# Load YOLO model at startup
try:
    model = YOLO("models/parking_lot.pt")  # path to your YOLO weights
    device = "cuda" if torch.cuda.is_available() else "cpu"
    model_loaded = True
except Exception as e:
    model = None
    device = "unavailable"
    model_loaded = False



# Endpoints
@app.get("/healthz")
def health(db: Session = Depends(get_db)):
    db_status = "ok"
    try:
        db.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"error: {e}"
    return {
        "status": "ok" if db_status == "ok" and model_loaded else "degraded",
        "db": db_status,
        "model_loaded": model_loaded,
        "device": device,
    }

@app.post("/detect/vehicle")
def detect_vehicle_stub():
    if not model_loaded:
        return {"error": "model not loaded"}
        
    # for now just a placeholder — later replace with uploaded image/frame
    # results = model.predict("data/processed/car_specs_v0_filtered.csv", imgsz=640)  
    # detections = []
    # for r in results:
    #     for box in r.boxes:
    #         detections.append({
    #             "x1": float(box.xyxy[0][0]),
    #             "y1": float(box.xyxy[0][1]),
    #             "x2": float(box.xyxy[0][2]),
    #             "y2": float(box.xyxy[0][3]),
    #             "conf": float(box.conf[0]),
    #             "cls": model.names[int(box.cls[0])]
    #         })
    # return {"detections": detections}
    return {
        "detections": [
            {"x1": 120.0, "y1": 200.0, "x2": 320.0, "y2": 400.0, "conf": 0.87, "cls": "car"},
            {"x1": 400.0, "y1": 220.0, "x2": 550.0, "y2": 380.0, "conf": 0.92, "cls": "car"}
        ]
    }

@app.get("/lots/{lot_id}/spots")
def get_spots(lot_id: str, db: Session = Depends(get_db)):
    spots = db.query(models.Spot).filter(models.Spot.lot_id == lot_id).all()
    return [{"id": s.id, "row": s.row, "ev": s.ev, "ada": s.ada} for s in spots]

@app.post("/recommend")
def recommend_stub():
    return {
        "top_spots": [
            {"id": "A-27", "reason": "Near entrance, EV-ready"},
            {"id": "A-15", "reason": "Wide space, buffered"},
            {"id": "B-03", "reason": "Close to exit"}
        ]
    }

@app.post("/chat")
def chat_stub(query: dict):
    return {"query": query, "response": "Closest EV midsize between two empty spots is A-27."}