# backend/app/nlp/nl_parse.py
import re

def parse_request(text: str) -> dict:
    """
    Parses a parking/EV request and returns a dictionary with extracted features.
    """
    text_lower = text.lower()
    result = {}

    # Helper function to check if a keyword is negated
    def is_negated(keyword, text):
        # Patterns that indicate negation of the keyword
        negation_patterns = [
            rf"\bwithout\b.*{keyword}",
            rf"\bno\b.*{keyword}",
            rf"\bnot\b.*{keyword}",
            rf"\bnot for\b.*{keyword}",
            rf"{keyword}.*\bnot\b",
            rf"{keyword}.*\bno\b",
            rf"{keyword}.*\bwithout\b",
            rf"{keyword}.*\bnot for\b",
        ]
        return any(re.search(pattern, text) for pattern in negation_patterns)

    # ADA detection - simple and direct
    if re.search(r"\b(handicap|ada|disabled)\b", text_lower):
        result["ada"] = True

    # EV detection with improved negation handling
    ev_mentioned = re.search(r"\bev\b|\belectric\b", text_lower)
    if ev_mentioned:
        # Use the is_negated function for EV as well
        ev_negated = is_negated(r"(ev|electric)", text_lower)
        
        # Don't mark EV if it's about adjacent empty spots
        adjacent_ev = re.search(r"(empty|between).*(ev|electric)", text_lower)
        
        if not ev_negated and not adjacent_ev:
            result["ev"] = True

    # Vehicle size detection
    if re.search(r"\bcompact\b|\bsmall car\b", text_lower):
        result["size"] = "compact"
    elif re.search(r"\bmidsize\b", text_lower):
        result["size"] = "midsize"
    elif re.search(r"\bsuv\b", text_lower):
        result["size"] = "suv"
    elif re.search(r"\bfull size\b|\bfull\b", text_lower):
        result["size"] = "full"
    elif re.search(r"\btruck\b", text_lower):
        result["size"] = "truck"

    # Connector type detection with negation handling
    if (re.search(r"\b(dc fast|fast charger|fast charging|dc_fast)\b", text_lower) and 
        not is_negated(r"(fast charger|fast charging|dc fast)", text_lower)):
        result["connector"] = "dc_fast"
    elif (re.search(r"\bccs\b", text_lower) and 
          not is_negated(r"ccs", text_lower)):
        result["connector"] = "ccs"
    elif (re.search(r"\bj1772\b", text_lower) and 
          not is_negated(r"j1772", text_lower)):
        result["connector"] = "j1772"

    # Buffered detection
    if re.search(r"\bbuffered\b|\bbetween two\b", text_lower):
        result["buffered"] = True

    # Near detection - more flexible patterns
    # Check for any "near" mention first, then filter out unwanted cases
    if re.search(r"\bnear\b|\bclose to\b", text_lower):
        # Now filter out cases where near shouldn't be true
        has_far = re.search(r"\bfar\b|\bfar from\b|\bfar away\b", text_lower)
        near_exit = re.search(r"\bnear.*exit\b", text_lower)
        near_stadium = re.search(r"\bnear.*stadium\b", text_lower)
        
        # If near is mentioned AND it's not about exit/far/stadium, set near=True
        if not has_far and not near_exit and not near_stadium:
            result["near"] = True

    return result