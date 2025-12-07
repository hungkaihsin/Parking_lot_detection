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

@router.post("/chat")
def chat_stub(input: ChatInput):
    """Stub for the chat endpoint: returns a placeholder response.""" 
    return {"reply": f"Stub response for: {input.text}"}
