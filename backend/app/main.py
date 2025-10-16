from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import text
from dotenv import load_dotenv
from ultralytics import YOLO
import torch
import logging
import datetime
from pydantic import BaseModel
from typing import List, Dict, Any, Optional


from .db import get_db
from . import models
from . import recommender

from .chat import router as chat_router

# --- Logging Setup ---
# Create logs directory if it doesn't exist
import os
os.makedirs("logs", exist_ok=True)

# Set up logging
log_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
log_file = 'logs/recommendations.log'
file_handler = logging.FileHandler(log_file)
file_handler.setFormatter(log_formatter)
file_handler.setLevel(logging.INFO)
app_logger = logging.getLogger('recommender_api')
app_logger.addHandler(file_handler)
app_logger.setLevel(logging.INFO)


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
    """
    Returns a list of all stalls in a given lot, including their
    geometry and features.
    """
    stalls = (
        db.query(models.Stall)
        .filter(models.Stall.lot_id == lot_id)
        .options(joinedload(models.Stall.features))
        .all()
    )
    
    response = []
    for s in stalls:
        if s.features:
            response.append({
                "id": s.id,
                "lot_id": s.lot_id,
                "geom_wkt": s.geom_wkt,
                "features": {
                    "is_ada": s.features.is_ada,
                    "is_ev": s.features.is_ev,
                    "connectors": s.features.connectors,
                    "width_class": s.features.width_class,
                    "dist_to_entrance": s.features.dist_to_entrance
                }
            })
    return response

class RecommendationRequest(BaseModel):
    is_ada: Optional[bool] = None
    is_ev: Optional[bool] = None
    connector: Optional[str] = None
    size_class: Optional[int] = None

@app.post("/recommend")
def recommend(
    request: RecommendationRequest,
    db: Session = Depends(get_db)
):
    """
    Recommends parking stalls based on structured user preferences.
    """
    start_time = datetime.datetime.now()

    # 1. Get all stalls from the database
    # In a real application, you would filter for available stalls here
    available_stalls = (
        db.query(models.Stall)
        .options(joinedload(models.Stall.features))
        .all()
    )

    # 2. Get recommendations
    recommendations = recommender.recommend_stalls(
        available_stalls=available_stalls,
        preferences=request.dict()
    )

    # 3. Log the decision
    end_time = datetime.datetime.now()
    latency = (end_time - start_time).total_seconds()
    
    log_entry = {
        "request_id": str(start_time.timestamp()),
        "preferences": request.dict(),
        "num_candidates": len(available_stalls),
        "num_results": len(recommendations),
        "top_recommendation": recommendations[0] if recommendations else None,
        "latency_ms": latency * 1000,
    }
    app_logger.info(log_entry)


    return {"recommendations": recommendations[:3]}


@app.post("/chat")
def chat_stub(query: dict):
    return {"query": query, "response": "Closest EV midsize between two empty spots is A-27."}

app.include_router(chat_router)