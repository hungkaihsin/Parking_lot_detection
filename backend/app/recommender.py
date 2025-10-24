from typing import List, Dict, Any
from . import models

def recommend_stalls(
    available_stalls: List[models.Stall],
    preferences: Dict[str, Any]
) -> List[Dict[str, Any]]:
    """
    Recommends parking stalls based on user preferences.

    Args:
        available_stalls: A list of available Stall objects.
        preferences: A dictionary of user preferences.

    Returns:
        A ranked list of recommended stalls with reasons.
    """
    # 1. Hard Filters
    filtered_stalls = _apply_hard_filters(available_stalls, preferences)

    # 2. Soft Preferences (Ranking)
    ranked_stalls = _apply_soft_preferences(filtered_stalls, preferences)

    # 3. Format Output
    return _format_recommendations(ranked_stalls)

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
        if not preferences.get("near"):
            score -= stall.features.dist_to_entrance
            reasons.append(f"Distance: {stall.features.dist_to_entrance:.2f}m")

        # 2. Buffered (between two empty spots)
        if preferences.get("buffered"):
            is_buffered = all(not n.is_occupied for n in stall.neighbors)
            if is_buffered:
                score += 0.5  # Add a bonus for buffered stalls
                reasons.append("Buffered spot")

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
) -> List[Dict[str, Any]]:
    """Formats the ranked stalls into the final output."""
    recommendations = []
    for item in ranked_stalls:
        stall = item["stall"]
        recommendations.append({
            "stall_id": stall.id,
            "lot_id": stall.lot_id,
            "score": item["score"],
            "reasons": item["reasons"],
            "features": {
                "is_ada": stall.features.is_ada,
                "is_ev": stall.features.is_ev,
                "connectors": stall.features.connectors,
                "width_class": stall.features.width_class,
                "dist_to_entrance": stall.features.dist_to_entrance,
            }
        })
    return recommendations
