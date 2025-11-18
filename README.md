# 🚗 Parking Lot Recommender (Phase 1)

This project uses **FastAPI**, **PostgreSQL (via Docker)**, and **Alembic** to build the backend service for a parking lot recommender system.

---

## 📦 Setup Instructions

### 1. Clone the repo
```bash
git clone <your-repo-url>
cd backend   # IMPORTANT: run all commands from inside the backend folder
```

### 2. Install Docker
- Download and install **Docker Desktop**: https://www.docker.com/products/docker-desktop/
- Open Docker Desktop before running any commands.  
  (You should see the whale icon running in your menu bar/system tray.)

### 3. Configure environment variables
Copy `.env.example` → `.env`:
```bash
cp .env.example .env
```

Then edit `.env` if needed (DB user/password must match your Docker config):
```
DATABASE_URL=postgresql+psycopg2://postgres:password@localhost:5432/parkinglot
```

> ⚠️ Do not commit `.env` to GitHub. Only `.env.example` is shared.

> **If you are running API + DB entirely in Docker (recommended):** use the Docker service name `db` instead of `localhost`:
>
> ```
> DATABASE_URL=postgresql+psycopg2://postgres:password@db:5432/parkinglot
> ```
>
> And run Alembic inside the container:
> ```bash
> docker compose up -d --build
> docker compose exec api alembic upgrade head
> ```

### 4. Start PostgreSQL with Docker
Make sure Docker Desktop is running, then (from inside `backend/`):
```bash
docker compose up -d db
```
This starts a Postgres 15 database on `localhost:5432` (mapped from the `db` container).

### 5. Initialize database schema (Alembic)
**Recommended (Docker):**
```bash
docker compose up -d --build          # builds/starts api + db if not running
docker compose exec api alembic upgrade head
```

**If you intentionally run Alembic on the host (hybrid mode):**
```bash
alembic upgrade head
```

### 6. Run the FastAPI server
- **All-Docker (recommended):** the API container starts Uvicorn automatically via `start.sh`.
- **Host run (hybrid mode):**
  ```bash
  uvicorn app.main:app --reload --port 8000
  ```

Open http://127.0.0.1:8000/docs to see Swagger UI.

---

## 🚦 API Endpoints

### System Health

#### `GET /healthz`

Checks the operational status of the API, database, and machine learning model.

**Response (Success):**
```json
{
  "status": "ok",
  "db": "ok",
  "model_loaded": true,
  "device": "cpu"
}
```

**Response (Degraded):**
```json
{
  "status": "degraded",
  "db": "error: connection failed",
  "model_loaded": true,
  "device": "cpu"
}
```

---

### Parking Lot Management

#### `GET /lots/{lot_id}/spots`

Retrieves a detailed list of all parking stalls for a given `lot_id`, including their geometry and features.

**Example:**
```bash
curl http://127.0.0.1:8000/lots/main_lot/spots
```

**Response:**
```json
[
  {
    "id": "A-01",
    "lot_id": "main_lot",
    "geom_wkt": "POLYGON(...)",
    "features": {
      "is_ada": false,
      "is_ev": true,
      "connectors": "J1772",
      "width_class": 1,
      "dist_to_entrance": 15.5
    }
  }
]
```

#### `POST /lots/{lot_id}/predict`

Analyzes an uploaded image of a parking lot to detect occupied stalls, updates their state in the database, and logs vehicle arrival/departure events.

**Example:**
```bash
curl -X POST http://127.0.0.1:8000/lots/main_lot/predict \
  -F "file=@/path/to/your/image.jpg"
```

**Response:**
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

---

### Recommendations

#### `POST /recommend`

Recommends the best available parking stalls based on structured criteria or a natural language query.

**1. Natural Language Query:**

Use the `query` field to make requests in plain English.

**Example:**
```bash
curl -X POST http://127.0.0.1:8000/recommend \
  -H "Content-Type: application/json" \
  -d '{"query": "I need a spot for my truck, preferably buffered"}'
```

**2. Structured Request:**

Provide specific feature requirements for fine-grained control.

**Example:**
```bash
curl -X POST http://127.0.0.1:8000/recommend \
  -H "Content-Type: application/json" \
  -d '{
    "is_ev": true,
    "connector": "J1772",
    "size_class": 2,
    "buffered": true
  }'
```

**Response:**
```json
{
  "recommendations": [
    {
      "stall_id": "C-12",
      "lot_id": "main_lot",
      "score": 0.95,
      "reasons": ["EV charging available (J1772)", "Buffered spot", "Good size match"],
      "features": {
        "is_ev": true,
        "is_ada": false,
        "connectors": "J1772",
        "width_class": 2,
        "dist_to_entrance": 45.2,
        "size": "full"
      },
      "badges": ["EV", "Buffered"]
    }
  ]
}
```

#### `POST /chat`

A stub endpoint for conversational recommendations.

**Example:**
```bash
curl -X POST http://127.0.0.1:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"text": "Where can I park my SUV?"}'
```

**Response:**
```json
{
  "query": {"text": "Where can I park my SUV?"},
  "response": "Closest EV midsize between two empty spots is A-27."
}
```

---

### Miscellaneous

#### `POST /detect/vehicle`

A stub endpoint demonstrating a vehicle detection model.

**Response:**
```json
{
  "detections": [
    {
      "x1": 120.0, "y1": 200.0, "x2": 320.0, "y2": 400.0,
      "conf": 0.87, "cls": "car"
    }
  ]
}
```

#### `GET /housekeeping/download`

Downloads a specified file from the server's designated artifacts directory. Requires a `path` query parameter.

**Example:**
```bash
curl "http://127.0.0.1:8000/housekeeping/download?path=logs/recommendations.log" -o recommendations.log
```

---

## 📑 Dependencies

- Python libraries are installed **inside the Docker image** from `requirements.txt` (via the `Dockerfile`).  
- To add a package permanently:
  ```bash
  # add it to requirements.txt, then rebuild
  docker compose up -d --build
  ```
- For a quick test only (won’t persist after rebuild):
  ```bash
  docker compose exec api pip install <package>
  ```

---

## 🔄 Daily Workflow

1. Start services:
   ```bash
   docker compose up -d
   ```
2. Run migrations (only if models changed):
   ```bash
   docker compose exec api alembic revision --autogenerate -m "update schema"
   docker compose exec api alembic upgrade head
   ```
3. Tail API logs (hot reload is enabled):
   ```bash
   docker compose logs -f api
   ```
4. Test endpoints at:
   - `/healthz` → check DB
   - `/docs` → Swagger UI
5. Stop services:
   - `docker compose down`  
   - Add `-v` to wipe DB data: `docker compose down -v` (⚠ irreversibly deletes the database volume)

---

## 🧪 Quick DB Checks

Non-interactive:
```bash
docker compose exec db psql -U postgres -d parkinglot
```

Interactive:
```bash
docker compose exec db psql -U postgres -d parkinglot
\dt         -- list tables
\d <table>  -- describe a table
\q          -- quit
```

---

## 🧰 Notes about Docker files

- **Dockerfile** builds the API image, installs `requirements.txt`, and includes tools needed for Postgres/Alembic.
- **start.sh** waits for the DB, runs `alembic upgrade head`, then starts Uvicorn with reload for development.
- **docker-compose.yml** defines `db`, `api`, and (optionally) Adminer on port `8080`.
- Keep `.env` out of git; commit `.env.example` with safe defaults.


---

## 🐳 Docker-Only Workflow (no local Python)

> Use this if you want to run **everything inside containers**.

### Start API + Postgres
```bash
# from backend/
docker compose up -d --build
```
This builds the API image and starts `db` (Postgres) and `api` (FastAPI). The API startup script waits for DB, runs migrations, then launches Uvicorn.

### Run commands inside the API container
```bash
# open a shell in the api container
docker compose exec api bash

# now you're inside Docker:
alembic current
alembic revision --autogenerate -m "update schema"
alembic upgrade head
pytest -q              # if you have tests
python app/seed.py     # run any one-off scripts
exit
```

### Check the DB (inside its container)
```bash
docker compose exec db psql -U postgres -d parkinglot
```

### Logs & hot reload
```bash
docker compose logs -f api
```

### Stop / clean
```bash
docker compose down        # stop
docker compose down -v     # stop and DELETE DB volume (wipes data)
```

---

## 📁 Recommended Repo Layout (data & models)

Keep big datasets **outside** `backend/` and small deployable weights **inside** `backend/`:

```
repo-root/
├─ backend/
│  ├─ app/
│  ├─ models/
│  │  ├─ det/
│  │  │  └─ veh_v0/
│  │  │     ├─ weights/
│  │  │     │  └─ best.pt
│  │  │     ├─ data.yaml
│  │  │     ├─ params.json
│  │  │     └─ metrics.json
│  └─ .env
├─ data/
│  ├─ raw/
│  │  └─ car_spec_1945_2020.csv
│  └─ processed/
│     └─ car_specs_v0_filtered.csv
├─ training/
│  └─ runs/               # large training artifacts
└─ notebooks/
```

**.env examples**
```
# backend/.env
# For API
DATABASE_URL=postgresql+psycopg2://postgres:password@db:5432/parkinglot
MODEL_DIR=backend/models/det/veh_v0/weights
CAR_SPEC_PATH=./data/processed/car_specs_v0_filtered.csv
# For Postgres container
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
POSTGRES_DB=parkinglot
```

**.gitignore hints**
```
data/raw/*
training/runs/*
**/weights/*.pt
**/weights/*.onnx
**/weights/*.engine
.env
```

---

## 🧪 One-off: run a Python module inside Docker (no shell)
```bash
docker compose exec api python app/your_module.py
```

## 🔧 Install new Python deps (persistently)
1) Add the package to `backend/requirements.txt`  
2) Rebuild:
```bash
docker compose up -d --build
```

## Natural Language Parking Recommendations

Use the `/recommend` endpoint to find parking spots using natural language queries. You can also use the `/recommend/nl` endpoint, which is an alias for `/recommend`.

### Quick Examples

```bash
# Basic requests
curl -X POST http://127.0.0.1:8000/recommend/nl \
  -H "Content-Type: application/json" \
  -d '{"query": "compact car spot"}'

# EV charging
curl -X POST http://127.0.0.1:8000/recommend/nl \
  -H "Content-Type: application/json" \
  -d '{"query": "ev spot with fast charger"}'

# Accessibility
curl -X POST http://127.0.0.1:8000/recommend/nl \
  -H "Content-Type: application/json" \
  -d '{"query": "handicap parking near entrance"}'

# Complex requests
curl -X POST http://127.0.0.1:8000/recommend/nl \
  -H "Content-Type: application/json" \
  -d '{"query": "full size buffered ev spot with ccs"}'
```

### Supported Features

- Vehicle sizes: compact, midsize, suv, full, truck
- EV charging: ev/electric with dc_fast, ccs, j1772 connectors
- Accessibility: handicap, ada, disabled 
- Spot features: buffered, near entrance
- Negations: not, no, without (e.g., "not an EV")

### Response Example

```json
{
  "recommendations": [
    {
      "stall_id": "C-12",
      "lot_id": "main_lot",
      "score": 0.95,
      "reasons": ["EV charging available (J1772)", "Buffered spot", "Good size match"],
      "features": {
        "is_ev": true,
        "is_ada": false,
        "connectors": "J1772",
        "width_class": 2,
        "dist_to_entrance": 45.2,
        "size": "full"
      },
      "badges": ["EV", "Buffered"]
    }
  ]
}
```
