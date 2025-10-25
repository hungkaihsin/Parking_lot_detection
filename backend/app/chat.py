# backend/app/chat.py
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session, joinedload
from . import models, recommender, schemas
from .db import get_db
from .nlp.nl_parse import parse_request

router = APIRouter()

class ChatInput(BaseModel):
    text: str

@router.post("/recommend/nl", response_model=schemas.NLRecommendationResponse)
def recommend_nl(input: ChatInput, db: Session = Depends(get_db), offset: int = 0, limit: int = 100):
    """
    Endpoint that receives text, parses it for preferences, and returns stall recommendations.
    """
    # 1. Parse the natural language request
    preferences = parse_request(input.text)

    # 2. Get available stalls from the database
    available_stalls = db.query(models.Stall).options(joinedload(models.Stall.features)).filter(models.Stall.is_occupied == False).all()

    # 3. Get recommendations
    recommendations = recommender.recommend_stalls(available_stalls, preferences, offset=offset, limit=limit)

    return {"recommendations": recommendations, "parsed_preferences": preferences}

@router.post("/chat")
def chat_stub(input: ChatInput):
    """Stub for the chat endpoint: returns a placeholder response."""
    return {"reply": f"Stub response for: {input.text}"}
