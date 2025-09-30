import json
from pathlib import Path
from app.nlp.nl_parse import parse_request

def test_parsing():
    """Reads test cases from JSONL and checks parser output."""
    file_path = Path(__file__).parent / "tests_parsing.jsonl"
    with open(file_path, "r") as f:
        for line in f:
            case = json.loads(line)
            text, expected = case["text"], case["expected"]
            result = parse_request(text)
            assert result == expected, f"FAILED for: {text}\nExpected: {expected}\nGot: {result}"
