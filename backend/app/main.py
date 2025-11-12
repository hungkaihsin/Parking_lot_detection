from fastapi import FastAPI, Depends, UploadFile, Body, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import text
from dotenv import load_dotenv
from ultralytics import YOLO
import torch
import logging
import datetime
import os
import subprocess

from .db import get_db, get_cached_stall_catalog
from . import models
from . import config
from .detection import get_occupied_stalls
from . import recommender
from .nlp.nl_parse import parse_request

# --- Logging Setup ---
# Create logs directory if it doesn't exist
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

# --- Globals ---
model = None
model_loaded = False
device = "unavailable"

def get_build_sha():
    """Returns the short git commit hash from the environment variable."""
    return os.getenv("GIT_SHA", "unknown")

# --- Application Lifecycle ---
@app.on_event("startup")
def startup_event():
    """
    Actions to be performed on application startup.
    - Load the appropriate YOLO model based on the profile.
    """
    global model, model_loaded, device
    
    if config.PROFILE == "day":
        model_path = "models/parking_lot.pt"
    elif config.PROFILE == "night":
        model_path = "models/parking_lot_night.pt"
    else:
        app_logger.warning(f"Invalid PROFILE '{config.PROFILE}'. Model not loaded.")
        return

    if not os.path.exists(model_path):
        app_logger.warning(f"Model file not found at {model_path}. Model not loaded.")
        return

    try:
        model = YOLO(model_path)
        device = "cuda" if torch.cuda.is_available() else "cpu"
        model.to(device)
        model_loaded = True
        app_logger.info(f"Successfully loaded model for '{config.PROFILE}' profile on '{device}'.")
    except Exception as e:
        app_logger.error(f"Failed to load model for profile '{config.PROFILE}': {e}")


# --- Endpoints ---
@app.get("/healthz")
def health(db: Session = Depends(get_db)):
    db_status = "ok"
    try:
        # Check if the database connection is responsive
        db.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"error: {e}"

    return {
        "status": "ok" if db_status == "ok" and model_loaded else "degraded",
        "db_status": db_status,
        "model_loaded": model_loaded,
        "profile": config.PROFILE,
        "build_sha": get_build_sha(),
    }

@app.post("/detect/vehicle")
def detect_vehicle_stub():
    if not model_loaded:
        raise HTTPException(status_code=503, detail="Model not loaded")
        
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

@app.post("/lots/{lot_id}/predict")
async def predict_stalls(lot_id: str, file: UploadFile, db: Session = Depends(get_db)):
    """
    Accepts an image of a parking lot, runs stall detection,
    updates stall occupancy states, and logs arrival/departure events.
    """
    image_bytes = await file.read()
    stalls = db.query(models.Stall).filter(models.Stall.lot_id == lot_id).all()

    if not stalls:
        return {"error": f"No stalls found for lot_id: {lot_id}"}

    occupancy_data = get_occupied_stalls(model, image_bytes, stalls)
    occupied_ids = set(occupancy_data.keys())

    arrivals = []
    departures = []

    for stall in stalls:
        is_now_occupied = stall.id in occupied_ids
        if is_now_occupied and not stall.is_occupied:
            # Vehicle has arrived
            stall.is_occupied = True
            vehicle_size = occupancy_data.get(stall.id, {}).get("size", "unknown")
            db.add(models.Event(stall_id=stall.id, event_type="arrive"))
            arrivals.append({"stall_id": stall.id, "size": vehicle_size})
        elif not is_now_occupied and stall.is_occupied:
            # Vehicle has departed
            stall.is_occupied = False
            db.add(models.Event(stall_id=stall.id, event_type="leave"))
            departures.append(stall.id)

    db.commit()

    return {
        "lot_id": lot_id,
        "arrivals": arrivals,
        "departures": departures,
        "occupied_stalls_count": len(occupied_ids),
    }

class RecommendationRequest(BaseModel):
    query: Optional[str] = Field(None, example="I need a spot for my truck")
    is_ada: Optional[bool] = Field(None, example=False)
    is_ev: Optional[bool] = Field(None, example=False)
    connector: Optional[str] = Field(None, example="J1772")
    size_class: Optional[int] = Field(None, example=1)
    near: Optional[bool] = Field(None, example=False)
    buffered: Optional[bool] = Field(False, example=False, description="Prefers a buffered spot (between two empty spots)")

@app.post("/recommend")
def recommend(
    request: RecommendationRequest,
    db: Session = Depends(get_db)
):
    """
    Recommends parking stalls based on structured user preferences or a natural language query.
    """
    start_time = datetime.datetime.now()

    if request.query:
        preferences = parse_request(request.query)
    else:
        preferences = request.dict(exclude_unset=True)

    # 1. Get all stalls from the cache
    cached_stalls = get_cached_stall_catalog(db)
    
    # Re-attach cached objects to the current session to prevent DetachedInstanceError
    available_stalls = [db.merge(s) for s in cached_stalls]

    # 2. Get recommendations
    recommendations = recommender.recommend_stalls(
        available_stalls=available_stalls,
        preferences=preferences
    )

    if not recommendations:
        raise HTTPException(status_code=404, detail="No stalls found matching the criteria.")

    # 3. Log the decision
    end_time = datetime.datetime.now()
    latency = (end_time - start_time).total_seconds()
    
    log_entry = {
        "request_id": str(start_time.timestamp()),
        "preferences": preferences,
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


@app.get("/housekeeping/download")
def download_artifact(path: str):
    """
    Downloads a specified artifact file from the server.
    For security, this endpoint only allows downloading files from a predefined base directory.
    """
    # Security: Prevent directory traversal attacks
    base_dir = os.path.abspath(".")  # Or a more specific, safe directory
    file_path = os.path.abspath(os.path.join(base_dir, path))

    if not file_path.startswith(base_dir):
        raise HTTPException(status_code=403, detail="Forbidden: Access is denied.")

    if not os.path.isfile(file_path):
        raise HTTPException(status_code=404, detail="File not found.")

    return FileResponse(file_path)