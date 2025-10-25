from typing import List, Dict, Any
from . import models
from .schemas import Recommendation, StallFeatureBase

def recommend_stalls(
    available_stalls: List[models.Stall],
    preferences: Dict[str, Any],
    offset: int = 0,
    limit: int = 100,
) -> List[Recommendation]:
    """
    Recommends parking stalls based on user preferences.

    Args:
        available_stalls: A list of available Stall objects.
        preferences: A dictionary of user preferences.
        offset: The starting index for pagination.
        limit: The maximum number of recommendations to return.

    Returns:
        A ranked and paginated list of recommended stalls with reasons.
    """
    # 1. Hard Filters
    filtered_stalls = _apply_hard_filters(available_stalls, preferences)

    # 2. Soft Preferences (Ranking)
    ranked_stalls = _apply_soft_preferences(filtered_stalls, preferences)

    # 3. Pagination + Formatting
    paginated_stalls = ranked_stalls[offset : offset + limit]
    return _format_recommendations(paginated_stalls)

def _apply_hard_filters(
    stalls: List[models.Stall],
    preferences: Dict[str, Any]
) -> List[models.Stall]:
    """Applies hard filters to the list of stalls."""
    filtered_stalls = stalls

    if preferences.get("is_ada"):
        filtered_stalls = [s for s in filtered_stalls if s.features.is_ada]

    if preferences.get("is_ev"):
        filtered_stalls = [s for s in filtered_stalls if s.features.is_ev]

    if preferences.get("connector"):
        filtered_stalls = [
            s for s in filtered_stalls
            if s.features.connectors and preferences["connector"] in s.features.connectors
        ]
    
    if preferences.get("size_class"):
        filtered_stalls = [
            s for s in filtered_stalls
            if s.features.width_class >= preferences["size_class"]
        ]

    return filtered_stalls

def _apply_soft_preferences(
    stalls: List[models.Stall],
    preferences: Dict[str, Any]
) -> List[Dict[str, Any]]:
    """Ranks stalls based on soft preferences."""
    ranked_stalls = []
    for stall in stalls:
        score = 0
        reasons = []

        # 1. Distance to entrance (lower is better)
        score -= stall.features.dist_to_entrance
        reasons.append(f"Distance: {stall.features.dist_to_entrance:.2f}m")

        # 2. Buffered (between two empty spots)
        # This will be implemented in Week 5

        # 3. Size match
        if preferences.get("size_class"):
            size_diff = stall.features.width_class - preferences["size_class"]
            if size_diff >= 0:
                score += 1 / (size_diff + 1) # Reward smaller size differences
                reasons.append(f"Size match bonus: +{1 / (size_diff + 1):.2f}")


        ranked_stalls.append({"stall": stall, "score": score, "reasons": reasons})

    # Sort stalls by score in descending order
    ranked_stalls.sort(key=lambda x: x["score"], reverse=True)
    return ranked_stalls

def _format_recommendations(
    ranked_stalls: List[Dict[str, Any]]
) -> List[Recommendation]:
    """
    Formats the ranked stalls into the final output using the Recommendation schema.
    """
    recommendations = []
    for item in ranked_stalls:
        stall = item["stall"]
        recommendations.append(
            Recommendation(
                stall_id=stall.id,
                lot_id=stall.lot_id,
                score=item["score"],
                reasons=item["reasons"],
                features=StallFeatureBase(
                    is_ada=stall.features.is_ada,
                    is_ev=stall.features.is_ev,
                    connectors=stall.features.connectors,
                    width_class=stall.features.width_class,
                    dist_to_entrance=stall.features.dist_to_entrance,
                )
            )
        )
    return recommendations

