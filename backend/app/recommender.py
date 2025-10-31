from typing import List, Dict, Any
from . import models
from .schemas import Recommendation, StallFeatureBase

size_map = {"compact": 0, "midsize": 1, "full": 2, "suv": 3, "truck": 4}

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
    if "size" in preferences and preferences["size"] in size_map:
        preferences["size_class"] = size_map[preferences["size"]]
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

    # --- THIS BLOCK IS THE ONLY CHANGE ---
    pref_size = preferences.get("size_class")

    if pref_size is not None:
        # Special rule: If user wants "compact", only show "compact".
        if pref_size == 0:  # 0 is "compact"
            filtered_stalls = [
                s for s in filtered_stalls
                if s.features.width_class == 0
            ]
        # Standard rule: Vehicle must fit in the stall.
        else:
            filtered_stalls = [
                s for s in filtered_stalls
                if s.features.width_class >= pref_size
            ]
    # --- END OF CHANGE ---

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
        if preferences.get("size_class") is not None:
            size_diff = stall.features.width_class - preferences["size_class"]
            if size_diff == 0:
                score += 1.0 # Exact match
                reasons.append("Exact size match")
            elif size_diff > 0:
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
    reversed_size_map = {v: k for k, v in size_map.items()}

    for item in ranked_stalls:
        stall = item["stall"]
        badges = []
        if stall.features.is_ev:
            badges.append("EV")
        if stall.features.is_ada:
            badges.append("ADA")
        if all(not n.is_occupied for n in stall.neighbors):
            badges.append("Buffered")
        
        size_name = "Unknown"
        if stall.features.width_class is not None:
            size_name = reversed_size_map.get(stall.features.width_class, "Unknown")
            badges.append(size_name)

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
                    size=size_name
                ),
                badges=badges
            )
        )
    return recommendations