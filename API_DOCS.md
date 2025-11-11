# Parking Lot Recommender API Documentation

This document provides detailed documentation for the Parking Lot Recommender API, including endpoint descriptions, request/response schemas, and error codes.

## Base URL

`http://127.0.0.1:8000`

---

## Authentication

No authentication is required for the current version of the API.

---

## Schemas

### StallFeature

Represents the specific features of a parking stall.

| Field | Type | Description |
| :--- | :--- | :--- |
| `is_ev` | boolean | `true` if the stall has EV charging. |
| `is_ada` | boolean | `true` if the stall is ADA-compliant. |
| `connectors` | string \| null | Comma-separated list of EV connector types (e.g., "J1772,CCS"). |
| `width_class` | integer | Numerical class representing stall width (e.g., 1: Compact, 2: Midsize, 3: Full). |
| `dist_to_entrance` | float | Distance in meters from the stall to the nearest entrance. |
| `size` | string \| null | Descriptive size of the stall (e.g., "compact", "full"). |

### Stall

Represents a single parking stall.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | string | The unique identifier for the stall (e.g., "A-01"). |
| `lot_id` | string | The ID of the parking lot this stall belongs to. |
| `geom_wkt` | string | The geometry of the stall in Well-Known Text (WKT) format. |
| `center_x` | float \| null | The x-coordinate of the stall's center point. |
| `center_y` | float \| null | The y-coordinate of the stall's center point. |
| `is_occupied` | boolean | `true` if the stall is currently occupied. |
| `features` | StallFeature | An object containing the stall's features. |

### Recommendation

Represents a single recommended parking stall.

| Field | Type | Description |
| :--- | :--- | :--- |
| `stall_id` | string | The unique ID of the recommended stall. |
| `lot_id` | string | The ID of the parking lot. |
| `score` | float | A score from 0.0 to 1.0 indicating the quality of the match. |
| `reasons` | array\[string] | A list of reasons why this stall was recommended. |
| `features` | StallFeature | The features of the recommended stall. |
| `badges` | array\[string] | A list of short-form badges for UI display (e.g., "EV", "Buffered"). |

---

## Endpoints

### `GET /healthz`

Checks the operational status of the API, database, and machine learning model.

- **Success Response (`200 OK`)**
  ```json
  {
    "status": "ok",
    "db": "ok",
    "model_loaded": true,
    "device": "cpu"
  }
  ```
- **Error Response (`200 OK` with degraded status)**
  ```json
  {
    "status": "degraded",
    "db": "error: connection failed",
    "model_loaded": false,
    "device": "unavailable"
  }
  ```

---

### `GET /lots/{lot_id}/spots`

Retrieves a list of all parking stalls for a given `lot_id`.

- **URL Params:**
  - `lot_id` (string, required): The ID of the parking lot.
- **Success Response (`200 OK`)**
  - **Body:** `array[Stall]`
- **Error Responses:**
  - `404 Not Found`: If no lot with the given `lot_id` exists.

---

### `POST /lots/{lot_id}/predict`

Analyzes an uploaded image to update the occupancy status of stalls in a lot.

- **URL Params:**
  - `lot_id` (string, required): The ID of the parking lot.
- **Request Body:**
  - `multipart/form-data` with a `file` field containing the image.
- **Success Response (`200 OK`)**
  ```json
  {
    "lot_id": "main_lot",
    "arrivals": [
      {"stall_id": "A-05", "size": "midsize"}
    ],
    "departures": ["B-02"],
    "occupied_stalls_count": 23
  }
  ```
- **Error Responses:**
  - `404 Not Found`: If no stalls are found for the given `lot_id`.
  - `422 Unprocessable Entity`: If the `file` is not provided.

---

### `POST /recommend`

Recommends parking stalls based on a natural language query or structured preferences.

- **Request Body:**
  ```json
  {
    "query": "I need a spot for my truck",
    "is_ada": false,
    "is_ev": false,
    "connector": null,
    "size_class": null,
    "near": false,
    "buffered": false
  }
  ```
  *Note: Either `query` or at least one of the other structured fields should be provided.*

- **Success Response (`200 OK`)**
  - **Body:**
    ```json
    {
      "recommendations": [
        {
          "stall_id": "C-12",
          "lot_id": "main_lot",
          "score": 0.95,
          "reasons": ["Buffered spot", "Good size match"],
          "features": {
            "is_ev": false,
            "is_ada": false,
            "connectors": null,
            "width_class": 3,
            "dist_to_entrance": 55.0,
            "size": "full"
          },
          "badges": ["Buffered"]
        }
      ]
    }
    ```

- **Error Responses:**
  - `404 Not Found`: If no stalls are found that match the specified criteria.
  - `422 Unprocessable Entity`: If the request body is invalid.

---

### `GET /housekeeping/download`

Downloads a specified artifact file from the server.

- **Query Params:**
  - `path` (string, required): The relative path to the file to download (e.g., `logs/recommendations.log`).
- **Success Response (`200 OK`)**
  - The raw file content.
- **Error Responses:**
  - `403 Forbidden`: If the path attempts to access a restricted directory (directory traversal).
  - `404 Not Found`: If the file at the specified path does not exist.
  - `422 Unprocessable Entity`: If the `path` parameter is missing.
