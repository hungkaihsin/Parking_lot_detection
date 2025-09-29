# backend/app/chat.py
from fastapi import APIRouter
from pydantic import BaseModel
from .nlp.nl_parse import parse_request

router = APIRouter()

class ChatInput(BaseModel):
    text: str

@router.post("/recommend/nl")
def recommend_nl(input: ChatInput):
    """Endpoint that receives text and returns parsed filters."""
    parsed = parse_request(input.text)
    return {"parsed": parsed}

@router.post("/chat")
def chat_stub(input: ChatInput):
    """Stub for the chat endpoint: returns a placeholder response."""
    return {"reply": f"Stub response for: {input.text}"}
