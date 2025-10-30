# backend/app/nlp/nl_parse.py
import re

def flexible_keyword_match(keywords_list, text):
    for k in keywords_list:
        for match in re.finditer(f"({k})", text):
            start, end = match.span()
            if (start == 0 or not text[start-1].isalnum()) and \
               (end == len(text) or not text[end].isalnum()):
                return True
    return False

def is_negated(keywords: list[str], text_to_search: str, proximity: int = 7) -> bool:
    text_lower = text_to_search.lower()
    negation_words = ["not", "no", "don't", "do not", "without"]

    for keyword_pattern in keywords:
        # Find all occurrences of the keyword pattern in the text
        # Use a more flexible regex to find the keyword, then validate it's a whole word
        for match in re.finditer(f"({keyword_pattern})", text_lower):
            # Ensure the match is a whole word
            start, end = match.span()
            if (start == 0 or not text_lower[start-1].isalnum()) and \
               (end == len(text_lower) or not text_lower[end].isalnum()):
                
                keyword_start_char = match.start()
                
                # Check for negation words before the keyword match
                for neg_word in negation_words:
                    # Find the last occurrence of the negation word before the keyword match
                    neg_word_index = text_lower.rfind(neg_word, 0, keyword_start_char)

                    if neg_word_index != -1:
                        # Calculate distance in words
                        substring = text_lower[neg_word_index + len(neg_word):keyword_start_char]
                        words_between = len(substring.split()) # Split by space to count words
                        if words_between <= proximity:
                            return True
    return False

def parse_vehicle_size(text: str) -> dict:
    """
    Parses vehicle size from a request and returns a dictionary with the extracted feature.
    Handles 'only' and negation for vehicle sizes.
    """
    text_lower = text.lower()
    result = {}

    size_keywords = {
        "compact": ["compacts?", "small cars?"],
        "midsize": ["midsizes?"],
        "suv": ["suvs?"],
        "full": ["full sizes?", "fulls?", "large cars?"],
        "truck": ["trucks?"]
    }

    # Check for "only" patterns first
    for size_type, patterns in size_keywords.items():
        for p in patterns:
            # Use a more flexible regex for "only" patterns
            only_match = re.search(rf"({p})(?:\s+\w+)*\s+only|only(?:\s+\w+)*\s+({p})", text_lower)
            if only_match:
                # Extract the matched keyword to check for whole word boundary
                matched_keyword = only_match.group(1) if only_match.group(1) else only_match.group(2)
                start, end = only_match.span()
                
                # Ensure the matched keyword is a whole word
                if (start == 0 or not text_lower[start-1].isalnum()) and \
                   (end == len(text_lower) or not text_lower[end].isalnum()):
                    
                    if is_negated([f"{size_type} only", f"only {size_type}"], text_lower):
                        result["size"] = f"not_{size_type}_only"
                    else:
                        result["size"] = f"{size_type}_only"
                    return result # Return immediately if "only" is found

    # Then check for general size mentions
    for size_type, patterns in size_keywords.items():
        if any(re.search(rf"\b{p}\b", text_lower) for p in patterns):
            negated_status = is_negated(patterns, text_lower)
            if negated_status:
                result["size"] = f"not_{size_type}"
            else:
                result["size"] = size_type
            return result # Return immediately if a general size is found

    return result

def parse_request(text: str) -> dict:
    """
    Parses a parking/EV request and returns a dictionary with extracted features.
    """
    text_lower = text.lower()
    result = {}

    # ADA detection
    ada_keywords = ["handicap", "handicapped", "ada", "disabled", "accessible"]
    if flexible_keyword_match(ada_keywords, text_lower):
        if is_negated(ada_keywords, text_lower):
            result["ada"] = False
        else:
            result["ada"] = True

    # EV detection
    ev_keywords = ["ev", "electric"]
    charging_keywords = ["charging", "charger"]

    # Check for explicit EV mentions
    ev_mentioned_explicitly = flexible_keyword_match(ev_keywords, text_lower)

    # Determine if EV is negated (considering both ev and charging keywords)
    ev_is_negated = is_negated(ev_keywords, text_lower) or \
                    is_negated(charging_keywords, text_lower) or \
                    re.search(r"\bnon-ev\b", text_lower)

    if ev_is_negated:
        result["ev"] = False
    elif ev_mentioned_explicitly:
        result["ev"] = True

    # Vehicle size detection
    result.update(parse_vehicle_size(text))

    # Connector type detection with negation handling
    dc_fast_keywords = ["dc fast", "fast charger", "fast charging", "dc_fast"]
    ccs_keywords = ["ccs"]
    j1772_keywords = ["j1772"]

    if flexible_keyword_match(dc_fast_keywords, text_lower):
        if is_negated(dc_fast_keywords, text_lower):
            result["connector"] = "no_dc_fast"
        else:
            result["connector"] = "dc_fast"
    elif flexible_keyword_match(ccs_keywords, text_lower):
        if is_negated(ccs_keywords, text_lower):
            result["connector"] = "no_ccs"
        else:
            result["connector"] = "ccs"
    elif flexible_keyword_match(j1772_keywords, text_lower):
        if is_negated(j1772_keywords, text_lower):
            result["connector"] = "no_j1772"
        else:
            result["connector"] = "j1772"

    # Buffered detection
    buffered_keywords = ["buffered", "between two"]
    if flexible_keyword_match(buffered_keywords, text_lower):
        if is_negated(buffered_keywords, text_lower):
            result["buffered"] = False
        else:
            result["buffered"] = True

    # Near/Far from entrance detection
    near_keywords = ["near", "close to"]
    far_keywords = ["far", "far from", "far away"]
    near_exit_keywords = ["near exit"]
    entrance_keywords = ["entrance"]

    # Handle 'near exit' preference first, as it's more specific
    if flexible_keyword_match(near_exit_keywords, text_lower):
        result["near_exit"] = True
        # If 'near exit' is mentioned, and 'entrance' is negated, then 'near' should be False
        if is_negated(entrance_keywords, text_lower):
            result["near"] = False
    
    # Handle general 'near' preference only if 'near_exit' is not set and 'near' is not already set
    if "near_exit" not in result and "near" not in result:
        if flexible_keyword_match(near_keywords, text_lower):
            if is_negated(near_keywords, text_lower):
                result["near"] = False
            else:
                result["near"] = True
    
    # Handle 'far from entrance' preference
    if flexible_keyword_match(far_keywords, text_lower):
        if is_negated(far_keywords, text_lower):
            result["far_from_entrance"] = False
        else:
            result["far_from_entrance"] = True

    return result
