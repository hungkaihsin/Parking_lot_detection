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

### 3. Create & activate Python environment
We recommend Conda or venv. Example with Conda:
```bash
conda create -n parkinglot python=3.12 -y
conda activate parkinglot
```

### 4. Install dependencies (from inside `backend/`)
Since `requirements.txt` is included in this repo, just run:
```bash
pip install -r requirements.txt
```

### 5. Configure environment variables
Copy `.env.example` → `.env`:
```bash
cp .env.example .env
```

Then edit `.env` if needed (DB user/password must match your Docker config):
```
DATABASE_URL=postgresql+psycopg2://postgres:password@localhost:5432/parkinglot
```

> ⚠️ Do **not** commit `.env` to GitHub. Only `.env.example` is shared.

### 6. Start PostgreSQL with Docker
Make sure Docker Desktop is running, then (from inside `backend/`):
```bash
docker compose up -d db
```
This starts a Postgres 15 database on `localhost:5432`.

### 7. Initialize database schema (Alembic)
Run migrations:
```bash
alembic upgrade head
```
Check tables inside Postgres:
```bash
docker exec -it parkinglot-db psql -U postgres -d parkinglot
\dt    -- list tables
\q     -- quit
```

### 8. Run the FastAPI server
```bash
uvicorn app.main:app --reload --port 8000
```

Open [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) to see Swagger UI.

---

## 🚦 Endpoints (Week 0 Stubs)

- `GET /healthz` → DB health check  
- `POST /detect/vehicle` → Stub vehicle detection  
- `GET /lots/{lot_id}/spots` → Query stalls by lot  
- `POST /recommend` → Stub recommendations  
- `POST /chat` → Stub chat interface  

---

## 📑 Requirements File

`requirements.txt` is already included in this repo.  
Everyone should install dependencies with:
```bash
pip install -r requirements.txt
```

This ensures consistent library versions across all teammates.

---

## 🔄 Daily Workflow

1. Start DB:
   ```bash
   docker compose up -d db
   ```
2. Run migrations (only if models changed):
   ```bash
   alembic revision --autogenerate -m "update schema"
   alembic upgrade head
   ```
3. Start backend:
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```
4. Test endpoints at:
   - `/healthz` → check DB
   - `/docs` → Swagger UI
5. Stop services:
   - `CTRL+C` to stop FastAPI  
   - `docker compose down` to stop Postgres (optional)
