from typing import List, Optional
from pydantic import BaseModel

class StallFeatureBase(BaseModel):
    is_ev: bool
    is_ada: bool
    connectors: Optional[str]
    width_class: int
    dist_to_entrance: float
    size: Optional[str]  # Add the size field

    class Config:
        orm_mode = True

class StallBase(BaseModel):
    id: str
    lot_id: str
    geom_wkt: str
    center_x: Optional[float]
    center_y: Optional[float]
    is_occupied: bool
    features: StallFeatureBase

    class Config:
        orm_mode = True

class Recommendation(BaseModel):
    stall_id: str
    lot_id: str
    score: float
    reasons: List[str]
    features: StallFeatureBase
    badges: List[str]  # Add the badges field

    class Config:
        orm_mode = True

class NLRecommendationResponse(BaseModel):
    recommendations: List[Recommendation]
    parsed_preferences: dict
