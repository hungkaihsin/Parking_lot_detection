# backend/app/nlp/nl_parse.py
import re

def parse_request(text: str) -> dict:
    """Parses a natural language request into structured filters."""
    t = text.lower()
    result = {}

    # EV / electric
    if "ev" in t or "electric" in t:
        result["ev"] = True

    # ADA / disabled
    if "ada" in t or "disabled" in t or "handicap" in t:
        result["ada"] = True

    # Near entrance
    if "near" in t or "close" in t or "entrance" in t:
        result["near"] = True

    # Between two empty spots (buffered)
    if "between two empty" in t or "buffered" in t:
        result["buffered"] = True

    # Car size
    for size in ["compact", "midsize", "full", "suv", "truck"]:
        if size in t:
            result["size"] = size
            break

    # Connectors
    if "j1772" in t:
        result["connector"] = "j1772"
    elif "ccs" in t:
        result["connector"] = "ccs"
    elif "fast" in t or "dc" in t:
        result["connector"] = "dc_fast"

    return result

