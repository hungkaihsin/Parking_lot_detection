# backend/app/nlp/nl_parse.py
import re

def parse_request(text: str) -> dict:
    """
    Parses a parking/EV request and returns a dictionary with extracted features.
    """
    text_lower = text.lower()
    result = {}

    # Helper function to check if a keyword is negated
    def is_negated(keywords: list[str], text_to_search: str) -> bool:
        # Patterns that indicate negation directly preceding the keyword
        negation_patterns = []
        for keyword in keywords:
            escaped_keyword = re.escape(keyword.strip())
            negation_patterns.extend([
                rf"\bnot\s+(?:an?\s+)?{escaped_keyword}s?\b",  # e.g., "not an EV", "not ADA"
                rf"\bno\s+{escaped_keyword}s?\b",            # e.g., "no EV charging"
                rf"\bwithout\s+{escaped_keyword}s?\b",       # e.g., "without CCS"
                rf"\bnot\s+for\s+{escaped_keyword}s?\b",    # e.g., "not for ev"
            ])
        return any(re.search(pattern, text_to_search) for pattern in negation_patterns)

    # ADA detection
    ada_keywords = ["handicap", "handicapped", "ada", "disabled", "accessible"]
    if any(re.search(r"\b" + k + r"\b", text_lower) for k in ada_keywords):
        if not is_negated(ada_keywords, text_lower):
            result["ada"] = True
        else:
            result["ada"] = False

    # EV detection
    ev_keywords = ["ev", "electric"]
    charging_keywords = ["charging", "charger"]

    ev_explicitly_mentioned = any(re.search(r"\b" + k + r"\b", text_lower) for k in ev_keywords)
    charging_explicitly_mentioned = any(re.search(r"\b" + k + r"\b", text_lower) for k in charging_keywords)

    # Determine if EV is negated
    ev_is_negated = is_negated(ev_keywords, text_lower) or is_negated(charging_keywords, text_lower) or re.search(r"\bnon-ev\b", text_lower)

    if ev_is_negated:
        result["ev"] = False
    elif ev_explicitly_mentioned:
        # Check if 'ev' is part of 'empty ev spots' or 'between two ev spots'
        if not re.search(r"(empty|between two)\s+ev\s+spots", text_lower):
            result["ev"] = True

    # Vehicle size detection with negation
    size_found = False
    drive_or_have_match = re.search(r"\b(drive|have)\s+(an?|my)?\s*(.*?)\b", text_lower)
    if drive_or_have_match:
        vehicle_desc = drive_or_have_match.group(3)
        if re.search(r"\bcompacts?\b|\bsmall cars?\b", vehicle_desc):
            result["size"] = "compact"
            size_found = True
        elif re.search(r"\bmidsize(s)?\b", vehicle_desc):
            result["size"] = "midsize"
            size_found = True
        elif re.search(r"\bsuvs?\b", vehicle_desc):
            result["size"] = "suv"
            size_found = True
        elif re.search(r"\bfull sizes?\b|\bfulls?\b|\blarge cars?\b", vehicle_desc):
            result["size"] = "full"
            size_found = True
        elif re.search(r"\btrucks?\b", vehicle_desc):
            result["size"] = "truck"
            size_found = True

    if not size_found:
        if re.search(r"\bcompacts?\b|\bsmall cars?\b", text_lower):
            if not is_negated(["compact", "small car"], text_lower):
                result["size"] = "compact"
            else:
                result["size"] = "not_compact"
            size_found = True
        elif re.search(r"\bmidsize(s)?\b", text_lower):
            if not is_negated(["midsize"], text_lower):
                result["size"] = "midsize"
            else:
                result["size"] = "not_midsize"
            size_found = True
        elif re.search(r"\bsuvs?\b", text_lower):
            if not is_negated(["suv"], text_lower):
                result["size"] = "suv"
            else:
                result["size"] = "not_suv"
            size_found = True
        elif re.search(r"\bfull sizes?\b|\bfulls?\b|\blarge cars?\b", text_lower):
            if not is_negated(["full size", "full", "large car"], text_lower):
                result["size"] = "full"
            else:
                result["size"] = "not_full"
            size_found = True
        elif re.search(r"\btrucks?\b", text_lower):
            if not is_negated(["truck"], text_lower):
                result["size"] = "truck"
            else:
                result["size"] = "not_truck"
            size_found = True

    # Connector type detection with negation handling
    dc_fast_keywords = ["dc fast", "fast charger", "fast charging", "dc_fast"]
    ccs_keywords = ["ccs"]
    j1772_keywords = ["j1772"]

    if any(re.search(r"\b" + k + r"\b", text_lower) for k in dc_fast_keywords):
        if not is_negated(dc_fast_keywords, text_lower):
            result["connector"] = "dc_fast"
        else:
            result["connector"] = "no_dc_fast"
    elif any(re.search(r"\b" + k + r"\b", text_lower) for k in ccs_keywords):
        if not is_negated(ccs_keywords, text_lower):
            result["connector"] = "ccs"
        else:
            result["connector"] = "no_ccs"
    elif any(re.search(r"\b" + k + r"\b", text_lower) for k in j1772_keywords):
        if not is_negated(j1772_keywords, text_lower):
            result["connector"] = "j1772"
        else:
            result["connector"] = "no_j1772"

    # Buffered detection
    buffered_keywords = ["buffered", "between two"]
    if any(re.search(r"\b" + k + r"\b", text_lower) for k in buffered_keywords):
        if not is_negated(buffered_keywords, text_lower):
            result["buffered"] = True
        else:
            result["buffered"] = False

    # Near/Far from entrance detection
    near_keywords = ["near", "close to"]
    far_keywords = ["far", "far from", "far away"]
    near_exit_keywords = ["near exit"]
    entrance_keywords = ["entrance"]

    near_explicitly_mentioned = any(re.search(r"\b" + k + r"\b", text_lower) for k in near_keywords) and not is_negated(near_keywords, text_lower)
    far_explicitly_mentioned = any(re.search(r"\b" + k + r"\b", text_lower) for k in far_keywords) and not is_negated(far_keywords, text_lower)
    near_exit_explicitly_mentioned = any(re.search(r"\b" + k + r"\b", text_lower) for k in near_exit_keywords)

    if near_exit_explicitly_mentioned:
        result["near_exit"] = True

    # Handle general 'near' preference
    if near_explicitly_mentioned and near_exit_explicitly_mentioned and is_negated(entrance_keywords, text_lower):
        result["near"] = False
    elif is_negated(near_keywords, text_lower):
        result["near"] = False
    elif near_explicitly_mentioned and not far_explicitly_mentioned and not near_exit_explicitly_mentioned:
        result["near"] = True

    # Handle general 'far_from_entrance' preference
    if is_negated(far_keywords, text_lower):
        result["far_from_entrance"] = False
    elif far_explicitly_mentioned and not near_explicitly_mentioned and not near_exit_explicitly_mentioned:
        result["far_from_entrance"] = True

    return result