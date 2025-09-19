from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from dotenv import load_dotenv

from .db import get_db
from . import models

# Load .env (ensures DATABASE_URL is available)
load_dotenv()

app = FastAPI(title="Parking Lot Recommender API")

@app.get("/healthz")
def health(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok", "db": "connected"}
    except Exception as e:
        return {"status": "error", "db_error": str(e)}

@app.post("/detect/vehicle")
def detect_vehicle_stub():
    return {"detections": [{"x1": 100, "y1": 200, "x2": 300, "y2": 400, "conf": 0.95, "cls": "car"}]}

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