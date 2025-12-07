
import os

# Profile setting: 'day' or 'night'
PROFILE = os.getenv("PROFILE", "day")

# Feature flags
STRICT_SIZE_FIT = os.getenv("STRICT_SIZE_FIT", "false").lower() in ("true", "1", "t")
BUFFERED_BOOST = os.getenv("BUFFERED_BOOST", "true").lower() in ("true", "1", "t")

# Performance
PREDICTION_TIMEOUT = float(os.getenv("PREDICTION_TIMEOUT", "30"))
RECOMMENDATION_TIMEOUT = float(os.getenv("RECOMMENDATION_TIMEOUT", "10"))

# Detection parameters
DETECTION_CONF = float(os.getenv("DETECTION_CONF", "0.25"))
DETECTION_IOU = float(os.getenv("DETECTION_IOU", "0.4"))
