# Parking Lot Recommender — Project Plan (with Database)

  

**Phase 1 dates:** **Sept 19 → Dec 7**

**Presentation:** **Dec 6 or Dec 8**

  

## Scope (Phase 1)

- Find cars in lot videos/photos

- Mark stalls **FREE/TAKEN** on a drawn map

- Understand plain English preferences (EV, ADA/disabled, **near**, **between two empty**, **size**)

- Recommend top spots + one-line reason

*(No license plates. iOS app later; tiny viewer only.)*

  

---

  

## 1) Roles & Ownership

  

- **Daniel (heavy, Backend/DB Lead)**

FastAPI server, **PostgreSQL + Alembic**, polygons editor, car specs merge, **/recommend**, **/chat**, WebSocket/live mock, packaging, privacy.

  

- **Jerry (heavy, Vision Lead)**

YOLO car detector, occupancy logic (hysteresis), vehicle crops, **size-class + color** classifiers, robustness/night tuning, latency.

  

- **Franco (medium, NLP Lead)**

**nl_parse** (text → filters), **/chat** orchestration, (optional) stall-text OCR correction, explanations (NLG templates), normalization & guardrails.

  

- **Matteo (light, Data & Support)**

**Data collection & intake**, dataset cleaning & dedup, neighbor map, iOS viewer, evaluation pages, demo video, reports.

  

---

  

## 2) Database Choice (explicit)

  

- **Primary DB:** **PostgreSQL 15+** (Docker) with **Alembic** migrations.

- **Optional:** **PostGIS** extension (nice-to-have for geospatial, not required).

- **Optional cache:** **Redis** for WebSocket fan-out (Phase 1 optional).

- **Blobs (videos/images):** local filesystem under `data/` (later S3/MinIO).

  

### Minimal Phase-1 Schema

  

```sql

-- 1) Stalls & attributes

CREATE TABLE spots (

id TEXT PRIMARY KEY, -- "A-27" or a UUID

lot_id TEXT NOT NULL DEFAULT 'LotA',

row TEXT,

geom_wkt TEXT NOT NULL, -- polygon (WKT). With PostGIS: geometry(POLYGON)

center_x DOUBLE PRECISION,

center_y DOUBLE PRECISION,

ev BOOLEAN DEFAULT FALSE,

connector TEXT, -- "J1772", "CCS"

power_kw DOUBLE PRECISION,

ada BOOLEAN DEFAULT FALSE

);

  

-- 2) Neighbors (for "buffered" logic)

CREATE TABLE spot_neighbors (

spot_id TEXT PRIMARY KEY REFERENCES spots(id) ON DELETE CASCADE,

left_id TEXT REFERENCES spots(id),

right_id TEXT REFERENCES spots(id)

);

  

-- 3) Processing runs (each replay)

CREATE TABLE runs (

run_id TEXT PRIMARY KEY, -- UUID

lot_id TEXT NOT NULL,

video_path TEXT,

started_at TIMESTAMP NOT NULL DEFAULT now(),

ended_at TIMESTAMP

);

  

-- 4) FREE/TAKEN timeline

CREATE TABLE spot_status (

run_id TEXT REFERENCES runs(run_id) ON DELETE CASCADE,

ts_ms BIGINT,

spot_id TEXT REFERENCES spots(id) ON DELETE CASCADE,

state TEXT CHECK (state IN ('FREE','TAKEN')),

PRIMARY KEY (run_id, ts_ms, spot_id)

);

  

-- 5) Raw detections (debug/metrics; optional)

CREATE TABLE detections (

run_id TEXT REFERENCES runs(run_id) ON DELETE CASCADE,

ts_ms BIGINT,

det_id BIGSERIAL PRIMARY KEY,

x1 DOUBLE PRECISION, y1 DOUBLE PRECISION,

x2 DOUBLE PRECISION, y2 DOUBLE PRECISION,

conf DOUBLE PRECISION,

cls TEXT -- 'car'

);

  

-- 6) Car specs (medians, optional to store in DB)

CREATE TABLE carspecs (

make TEXT,

model TEXT,

year INT,

size_class TEXT, -- compact/midsize/full/suv_truck

length_mm INT,

width_mm INT,

height_mm INT,

PRIMARY KEY (make, model, year)

);

  

-- 7) Model registry (optional but useful)

CREATE TABLE models (

name TEXT PRIMARY KEY, -- 'veh_v0', 'cls_size_v1', etc.

path TEXT,

metrics_json JSONB,

created_at TIMESTAMP DEFAULT now()

);

  

-- Helpful indexes

CREATE INDEX idx_spot_status_run_ts ON spot_status(run_id, ts_ms);

CREATE INDEX idx_spot_status_spot ON spot_status(spot_id);

CREATE INDEX idx_detections_run_ts ON detections(run_id, ts_ms);

CREATE INDEX idx_spots_row ON spots(row);

```

  

**Note:** If you enable **PostGIS** later, replace `geom_wkt` with `geom geometry(POLYGON, 3857)` (or your CRS), and compute distances/contains via spatial functions.

  

---

  

## 3) Data Collection Plan

  

### What to capture

- **Videos:** 12 clips (~1 min each): **4 Day**, **4 Dusk**, **4 Night** (2+ rows visible; include EV/ADA areas; cars arriving/leaving).

- **Photos:** ~30 stills of **EV/ADA signs/markings** and tricky lighting (glare, rain).

- **Variety:** compact/midsize/full/SUV-truck; multiple colors.

  

### How to capture

- Phone steady, **landscape**, **1080p**, no zoom; stand safely.

- Take close photos of **“EV ONLY”/wheelchair** signs (readable).

  

### File names

```

data/raw/2025-10-05_day_view1_sunny.mp4

data/raw/2025-10-05_dusk_view2_headlights.mp4

data/raw/2025-10-05_night_view3_rain.mp4

data/raw/2025-10-05_photos_signs_ev_j1772_7kw_01.jpg

```

  

### Intake (Matteo)

- Run `tools/intake_new_photos.py` (and `intake_new_videos.py` if split).

- Writes `data/intake/YYYY-MM-DD/...` + `data/reports/intake_report.json`.

- Update `docs/data_catalog.md` with one-line notes.

  

**Batch quality gate:** videos play; **2+ rows** visible; at least one **EV** & **ADA** sign; detector sees cars in sample frames.

  

---

  

## 4) Folder Map

```

backend/app/

main.py

chat.py

recommend.py

schemas.py

nlp/

nl_parse.py

stall_correct.py

config.yaml

configs/

detector_day.yaml

detector_night.yaml

data/raw/

data/intake/YYYY-MM-DD/

data/reports/intake_report.json

data/processed/

spots.geojson

spot_neighbors.json

spot_status.csv

carspecs.parquet

car_images_master.parquet

docs/

data_catalog.md

latency.html

final_eval.html

dashboard/

slides_assets/

models/

tools/

clean_tcc_images.py

intake_new_photos.py

intake_new_videos.py

replay_clip.py

run_e2e.py

build_neighbors.py

ios-stub/

alembic/

docker-compose.yml

.env.example

```

  

---

  

## 5) Success Targets

  

- **Car detection mAP** ≥ **85%**

- **FREE/TAKEN F1** ≥ **95%**

- **Size-class F1** ≥ **90%**, **Color acc** ≥ **85%**

- **NLP slot accuracy** ≥ **90%** (50 queries)

- **Recommendation**: Top-1 ≥ **75%**, Top-3 ≥ **90%**

- **Latency**: report median & P95 (detect & OCR if used)

  

---

  

## 6) Timeline — Week-by-Week (with DB tasks)

  

### Week 0 (Sep 19–21) — *Daniel + Jerry only*

  

**Daniel — API + DB bootstrap**

- Create `backend/app/*`, `alembic/`, `docker-compose.yml`, `.env.example`.

- Install: `pip install fastapi uvicorn sqlalchemy alembic psycopg2-binary shapely pydantic`

- **Start Postgres**: `docker compose up -d db`

- **Alembic init** and **first migration**: create tables from the **Minimal Schema**.

- Add stub endpoints:

`GET /healthz`, `POST /detect/vehicle`, `GET /lots/{id}/spots`, `POST /recommend`, `POST /chat`

- **Done:** DB reachable; stubs return JSON; `/healthz` ok.

  

**Jerry — Car detector v0 + replay skeleton**

- Train YOLO:

`pip install ultralytics`

`yolo task=detect mode=train data=data/roboflow/data.yaml model=yolo11n.pt imgsz=960 epochs=50`

- Save `models/det/veh_v0.pt`.

- `tools/replay_clip.py` with **TEMP grid**; produce 10 overlays + CSV.

- **Done:** weights saved; overlays & CSV exist.

  

---

  

### Week 1 (Sep 22–28) — *All four*

  

**Daniel — Wire detector to API + DB URL**

- Load `veh_v0.pt`; `/detect/vehicle` returns `[xyxy, conf, class]`.

- Add `/healthz` details `{model_loaded:true, device:"cpu/gpu", db:"ok"}` (do a test query).

- **Done:** sample returns boxes; DB connection verified.

  

**Jerry — Tune thresholds**

- Sweep `conf`/`iou` → `configs/detector_day.yaml`; export 20 overlays.

- **Done:** overlays look clean.

  

**Franco — Chat parser v0 + chat stub**

- `nl_parse.py`: rules for EV/ADA/near/buffered/size + J1772/CCS/fast/DC.

- Routes `/recommend/nl`, `/chat` (stub).

- Tests: `nl/tests_parsing.jsonl` (≥15 sentences).

- **Done:** tests pass; JSON correct.

  

**Matteo — TCC cleaning + iOS viewer + Data Round #1 (Day)**

- `clean_tcc_images.py` → `tcc_clean_index.parquet`.

- iOS stub: pick photo → `/detect/vehicle` → show JSON.

- Capture **4 Day videos** + sign photos; run intake; update catalog.

- **Done:** parquet created; iOS shows JSON; Day data ingested.

  

---

  

### Week 2 (Sep 29–Oct 5)

  

**Daniel — Real stall polygons → DB**

- Draw polygons with fields `{id,row,ev,connector,power_kw,ada}`; save `spots.geojson`.

- **Load to DB** (`spots`), compute and store `center_x/center_y`.

- Build neighbors (`spot_neighbors.json`) and **load to DB**.

- Serve `GET /lots/{id}/spots` from DB (or load into memory on boot).

- **Done:** polygons & neighbors in DB; endpoint returns GeoJSON.

  

**Jerry — FREE/TAKEN v1 (hysteresis)**

- IoU hit>0.2; TAKEN if ≥3/5 frames; else FREE.

- Output: `docs/demo/overlay.mp4`, `data/processed/spot_status.csv`.

- Optionally **persist** to `spot_status` with `run_id`.

- **Done:** overlay stable; (optional) DB has timeline rows.

  

**Franco — Stall text OCR correction (optional)**

- If painted IDs exist: regex + confusion map + fuzzy WRatio ≥85.

- **Done:** ≥90% exact (or skip).

  

**Matteo — Data Round #2 (Dusk/Night) + intake**

- 4 dusk + 4 night videos; run intake; update catalog.

- **Done:** reports present; dusk/night data captured.

  

---

  

### Week 3 (Oct 6–12)

  

**Daniel — Car specs → size medians + merge (DB optional)**

- `carspecs_normalize.py`: aliases, size_class from L/W thresholds, median L/W/H → `carspecs.parquet`.

- Merge with images → `car_images_master.parquet`.

- *(Optional)* load `carspecs` to DB for server-side joins.

- **Done:** ≥85% matched; all rows have size_class/dims.

  

**Jerry — Train size & color**

- Car crops; train `models/cls_size.pt`, `models/cls_color.pt`; confusion matrices.

- **Done:** Size F1 ≥0.85; Color acc ≥0.75 (stretch 0.85).

  

**Franco — Chat v1 end-to-end**

- `/chat`: parse → (stub) recommend → explanation sentence.

- Expand synonyms (EV/ADA/buffered/near/size/entrance).

- **Done:** slot accuracy ≥90% on 50 test queries.

  

**Matteo — Neighbor map (verify)**

- `build_neighbors.py` regeneration check; random spot audits.

- **Done:** neighbors correct.

  

---

  

### Week 4 (Oct 13–19)

  

**Daniel — Real `/recommend` + explanations (DB-backed)**

- **Filter** using DB data:

1) Fits (size_class/dims)

2) ADA (if requested)

3) EV + connector/power (if requested)

4) **Buffered** (use `spot_neighbors` + current FREE/TAKEN)

5) Near entrance (distance via centroid to entrance point)

- **Score**: `0.5*fit + 0.3*distance + 0.1*buffer + 0.1*ev`

- **Explain** template (one sentence).

- **Done:** realistic top-3 + clear reason; queries use DB rows.

  

**Jerry — Day/Night configs**

- Save `configs/detector_night.yaml`; stable night overlay.

- **Done:** looks steady.

  

**Franco — Chat polish (clarify once)**

- One-turn follow-up if key slot missing; quick-reply chips.

- **Done:** resolves in ≤1 turn.

  

**Matteo — E2E demo script**

- `run_e2e.py`: given a video + timestamp → overlay PNG + `top3.json`.

- **Done:** assets created.

  

---

  

### Week 5 (Oct 20–26)

  

**Jerry — Robustness + speed**

- Augmentations (low-light/glare/blur); measure median & P95 ms/frame.

- **Done:** mAP ≥0.80; `docs/latency.html` updated.

  

**Franco — Parser robustness**

- More synonyms; ignore unknowns; parse <10ms typical.

- **Done:** no crashes; accuracy holds.

  

**Daniel — WebSocket (mock live)** *(optional Redis)*

- `/ws/lot/{id}` pushes states 5–10 Hz; clients subscribe.

- Keep current state in memory (or Redis pub/sub if used).

- **Done:** live view smooth.

  

**Matteo — Latency page**

- Render detection & OCR timings; simple table.

- **Done:** `docs/latency.html` exists.

  

---

  

### Week 6 (Oct 27–Nov 2)

  

**Daniel — Error dashboard (reads from DB/files)**

- `docs/dashboard/index.html`: FP/FN thumbnails, chat parse summaries, links to frames & DB-backed samples.

- **Done:** browse mistakes; iterate fast.

  

**Jerry — Night tuning / smoothing**

- Reduce flicker; optional temporal smoothing for make/model.

- **Done:** steadier at night.

  

**Franco — Failure gallery**

- 15–20 hard NL queries with notes → `docs/slides_assets/nlp_failures/`.

- **Done:** assets curated.

  

**Matteo — Export assets**

- Save charts/frames as PNG with captions into `docs/slides_assets/`.

- **Done:** organized.

  

---

  

### Week 7 (Nov 3–9)

  

**Daniel — Polygon editor + clearer reasons**

- Web page to adjust vertices; re-save GeoJSON & **sync to DB**.

- Shorten reason text (one sentence, no jargon).

- **Done:** fix a stall in <1 minute; reasons read naturally.

  

**Jerry — (Optional) slim models + model cards**

- Try pruning/quantization; write `docs/models/` cards (data, metrics, limits).

- **Done:** cards exist; trade-offs noted.

  

**Franco — Chat performance + guardrails**

- Ensure p95 latency low; safe defaults always.

- **Done:** timings logged; no unhandled errors.

  

**Matteo — iOS polish**

- Show `make model • color • size_class` + one recommended stall & reason.

- **Done:** demo-ready screen.

  

---

  

### Week 8 (Nov 10–16)

- **Matteo:** intake late campus photos → mini report.

- **Daniel:** re-merge specs if new makes/models; (optional) update `carspecs` in DB.

- **Jerry:** final training pass; save `veh_final.pt`, `cls_size_final.pt`, `cls_color_final.pt`.

- **Franco:** freeze `nl/config.yaml` (synonyms, regex, templates).

- **Done:** final weights/configs versioned.

  

---

  

### Week 9 (Nov 17–23)

  

**Matteo — One-click evaluation (reads DB/files)**

- `docs/final_eval.html`: mAP; FREE/TAKEN F1 day/night; size/color acc; NL slot acc; latency; reco @1/@3.

  

**Daniel — API/privacy note (DB-aware)**

- `docs/API_CONTRACT.md`: list response fields; ensure no PII; DB retention notes.

  

**Jerry — Headline charts**

- Occupancy F1 & latency → `docs/slides_assets/`.

  

**Franco — Chat results**

- Tables & examples → `docs/slides_assets/`.

  

**Targets check:** mAP ≥85 • F1 ≥95 • Size ≥90 • Color ≥85 • NLP ≥90 • Reco @1 ≥75, @3 ≥90.

  

---

  

### Week 10 (Nov 24–Dec 1) — **Code Freeze**

- Tag release; export `requirements.txt`, `environment.yaml`, Docker Compose; archive weights + model cards under `artifacts/`.

- Slides start (Daniel + Jerry + Franco).

  

### Week 11 (Dec 2–7) — Slides & Practice

- **Daniel:** story & speaker notes; connect demo to slides.

- **Jerry:** best overlay clips & charts; rehearse timing.

- **Franco:** NL demos (EV/ADA/buffered/near); tidy explanations.

  

---

  

## 7) Mini Checklists

  

### DB Setup — Week 0 (Daniel)

- [ ] Docker Postgres up; `.env` has `DATABASE_URL`

- [ ] Alembic init & **first migration** (schema above)

- [ ] `/healthz` confirms DB connection

  

### Polygons & Neighbors — Week 2 (Daniel + Matteo)

- [ ] `spots.geojson` drawn & **loaded to DB**

- [ ] `spot_neighbors.json` built & **loaded to DB**

- [ ] `/lots/{id}/spots` serves data (from DB or cached)

  

### Recommender — Week 4 (Daniel)

- [ ] Uses DB filters: fits → ADA → EV → buffered → near

- [ ] Joins `spot_neighbors` for buffered logic

- [ ] Explanation pulls connector/power & distance

- [ ] Top-3 looks sensible on test queries

  

### Live State — Week 5 (Daniel)

- [ ] In-memory (or Redis) state for current FREE/TAKEN

- [ ] `/ws/lot/{id}` pushes 5–10 Hz

- [ ] Demo page shows changing colors

  

### Privacy — Week 9 (Daniel)

- [ ] `API_CONTRACT.md` lists only non-PII fields

- [ ] DB tables do not store PII or faces/plates

  

---

  

## 8) Demo Checklist (end)

  

- [ ] `/detect/vehicle` on a photo → boxes appear

- [ ] `overlay.mp4` shows stable FREE/TAKEN

- [ ] Chat “closest EV midsize between two empty” → top-3 + clear reason

- [ ] iOS viewer shows JSON & recommended spot

- [ ] Latency & Final Eval pages open with numbers