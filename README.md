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

## 🚦 Endpoints (Week 0 Stubs)

- `GET /healthz` → DB health check  
- `POST /detect/vehicle` → Stub vehicle detection  
- `GET /lots/{lot_id}/spots` → Query stalls by lot  
- `POST /recommend` → Stub recommendations  
- `POST /chat` → Stub chat interface  

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
docker compose exec db psql -U postgres -d parkinglot -c "\dt"
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
DATABASE_URL=postgresql+psycopg2://postgres:password@db:5432/parkinglot
MODEL_DIR=backend/models/det/veh_v0/weights
CAR_SPEC_PATH=./data/processed/car_specs_v0_filtered.csv
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
