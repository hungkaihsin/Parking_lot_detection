
# Parking Lot Recommender — Week‑by‑Week Plan
**Timeline:** Mon **Sep 29** → Sun **Dec 7** (PST)  
**Team:** Daniel (Backend & Recommender), Jerry (Vision), Franco (NLP & UX — lighter load)

---

## Goals at Finish (Dec 7)
- **Live stall detection (day & night):** YOLO → boxes → stall polygons + hysteresis ⇒ stable **FREE/TAKEN**.
- **Stall attributes:** EV, connector {J1772, CCS, DC fast}, ADA, width class (compact/midsize/full), distance‑to‑entrance, **buffered** (between two empty spots).
- **Vehicle size signal:** size‑from‑pixels v1 (classifier optional later).
- **Two recommendation modes:**
  1) **Auto‑recommend** from uploaded frame/clip (implicit intent).
  2) **Chat/NL recommend** from user text → slots → ranked stalls.
- **APIs:** `/predict/stalls`, `/recommend`, `/recommend/nl`, `/healthz`.
- **Targets:** Stall F1 (day ≥ 0.90, night ≥ 0.80); Constraint satisfaction ≥ 98%; Hit@3 ≥ 90%; p95 `/recommend/nl` ≤ 150 ms, `/predict/stalls` ≤ 180–200 ms.

---

## Roles
- **Jerry (Vision lead):** detector, occupancy + hysteresis, ignore masks, size signal, eval overlays, model card.
- **Daniel (Backend & Recommender):** DB schema (Postgres), stall catalog & geometry, neighbors/“buffered”, ranking, APIs, packaging & perf, healthchecks.
- **Franco (NLP & UX — lighter):** NL rules + test set, `/recommend/nl` integration, examples/UI, docs + demo script.

---

## Weekly Plan

### Week 2 (Sep 29–Oct 5) — Geometry + Vision → Stalls
**Jerry**
- Boxes→stall mapping + **hysteresis** (ON IoU≈0.12, OFF≈0.05, steady=8–12).  
- **Ignore mask** for non‑lot areas; CLI `tools/run_video.py … --polygons --cfg`.
- **Done:** 2–3 min **day** clip has <1 visible flicker/row; ≥90% stall states correct (spot‑check).

**Daniel**
- DB tables: `stalls`, `stall_features(is_ev,is_ada,connectors,width_class,dist_to_entrance)`, `neighbors`, `events`.  
- `scripts/load_stalls.py` imports GeoJSON, computes **dist_to_entrance**, builds **neighbors**.  
- `GET /lots/{id}/spots` + `/healthz` shows `db:"ok"`.  
- **Done:** catalog endpoint returns polygons & features; loader idempotent.

**Franco**
- Expand NL tests 15→**30**; add size/connector negatives.  
- README snippet with cURL examples for `/recommend/nl`.  
- **Done:** tests green; examples run.

---

### Week 3 (Oct 6–Oct 12) — Occupancy Service + Day MVP
**Jerry**
- Emit **events**: `arrive/leave (ts, stall_id, conf)`; write to DB.  
- Produce `runs/w2_day_eval/` overlays + CSV.  
- **Done:** events align with overlays on sample.

**Daniel**
- `POST /predict/stalls` (frame/clip) → FREE/TAKEN + features; persist events.  
- **Perf:** single frame CPU ≤ **200 ms**.  
- **Done:** meets latency & schema stable.

**Franco**
- Normalize parser enums to catalog (`connector∈{j1772,ccs,dc_fast}`, `size∈{compact,midsize,full,suv,truck}`).  
- **Done:** tests updated; outputs align.

**Milestone M1 (Oct 12):** **Vision MVP (day)** — `/predict/stalls` + catalog working.

---

### Week 4 (Oct 13–Oct 19) — Recommender v1 (Structured)
**Jerry**
- Finalize `configs/detector_day.yaml` via threshold sweep.  
- **Done:** day F1 (holdout) ≥ **0.88**.

**Daniel**
- **Ranking v1:** hard filters (EV/connector/ADA/size‑fit), soft prefs (−distance, +buffered, +size‑match).  
- `POST /recommend` (structured intent) + **decision logs** (`req_id, candidates, chosen, reason, latency`).  
- **Done:** top‑N with reasons; logs persisted.

**Franco**
- +**15** NL tests (ADA/connector combos) → total ≈45.  
- Swagger examples for `/recommend`.  
- **Done:** tests pass; examples visible.

---

### Week 5 (Oct 20–Oct 26) — NL → Reco Wiring + Constraints
**Jerry**
- Ship **day** evaluation pack (frames + GT stall states) for E2E tests.  
- **Done:** pack in `data/eval/day_pack/`.

**Daniel**
- Integrate **buffered** (neighbors both FREE) into ranking + badges.  
- Error codes when constraints impossible (e.g., “no J1772 stalls free”).  
- **Done:** constraint satisfaction ≥ **96%** on synthetic set; p95 `/recommend` ≤ **120 ms`.

**Franco**
- Wire `/recommend/nl` → `/recommend`; grow tests to **60** (negations like “not near entrance”, “no charging”).  
- **Done:** NL queries return correct stalls + reasons.

**Milestone M2 (Oct 26):** **Recommender MVP** (text → top‑N).

---

### Week 6 (Oct 27–Nov 2) — Night Start + Size v1
**Jerry**
- Collect **night** clip; add augments (exposure/blur); separate **night** config.  
- Implement **size‑from‑pixels v1** (box H/W/area thresholds).  
- **Done:** night F1 ≥ **0.75**; size macro‑F1 ≥ **0.70** on 100 labeled crops.

**Daniel**
- Enforce **size must‑fit** (truck ≠ compact).  
- `/housekeeping/download?path=…` for artifacts.  
- **Done:** invalid fits rejected; housekeeping works.

**Franco**
- NL patterns for size (“compact only”, “I drive a truck/SUV”).  
- UI badges/icons for EV/ADA/buffered/size.  
- **Done:** size intents parsed; UI shows badges.

---

### Week 7 (Nov 3–Nov 9) — E2E Robustness (Night) + Size Polish
**Jerry**
- Night error buckets (glare/blur) → targeted fixes (ignore zones, perspective jitter).  
- **Done:** night F1 ≥ **0.80**.

**Daniel**
- Better **reason strings**; cache catalog in memory for latency.  
- **Done:** p95 `/recommend/nl` ≤ **150 ms`.

**Franco**
- NL tests to **80** lines; more tricky phrasing & negations.  
- **Done:** tests pass; coverage improved.

**Milestone M3 (Nov 9):** **E2E demo** (day + night, size‑aware).

---

### Week 8 (Nov 10–Nov 16) — Quality Gates + Docs
**Jerry**
- Finalize day/night configs; regenerate eval overlays for report.  
- **Done:** day F1 ≥ **0.90**, night F1 ≥ **0.80** on holdouts.

**Daniel**
- **Feature flags:** strict size‑fit on/off, buffered boost on/off, day/night profile.  
- `/healthz`: `{model_loaded, profile:day|night, db_status, build_sha}`.  
- **Done:** flags toggle behavior; health reflects state.

**Franco**
- **User Guide + API docs** (schemas, examples, error codes).  
- **Done:** README/docs complete.

---

### Week 9 (Nov 17–Nov 23) — Performance + Stability
**Jerry**
- Micro‑optimizations (precompute polygon data, reduce allocations).  
- **Done:** `/predict/stalls` single‑frame CPU ≤ **180 ms`.

**Daniel**
- End‑to‑end perf profile; graceful timeouts/retries; log rotation.  
- **Done:** p95 end‑to‑end ≤ **300 ms** (CPU box); clean soak test.

**Franco**
- NL tests to **100** lines; finalize canned suite.  
- **Done:** 100/100 pass; E2E suite green.

**Milestone M4 (Nov 23):** Metrics pass & stable.

---

### Week 10 (Nov 24–Nov 30) — Packaging + Model Card *(Thanksgiving: lighter)*
**Jerry**
- Export **best weights** + **model card** (data, metrics, limits, privacy).  
- **Done:** `models/yolo_car_best.pt`, `reports/model_card.md` ready.

**Daniel**
- Docker hardening; **one‑command** run: `docker compose up -d`; health/readiness probes OK.  
- **Done:** fresh machine start works.

**Franco**
- **Demo script** (2–3 min): prompts, narrative, screenshots/GIFs.  
- **Done:** script approved.

---

### Week 11 (Dec 1–Dec 7) — Final Polish + Demo
**Jerry**
- Last calibration pass; refresh overlays; no regressions vs Week 8 metrics.

**Daniel**
- Tag release; freeze configs; metrics snapshot; clean logs.

**Franco**
- Run live demo; finalize README.

**Milestone M5 (Dec 7):** Final demo + release bundle.

---

## API Contracts (minimal)
- **`POST /predict/stalls`** → stall states + features (+ optional `vehicle.size`), logs events.  
- **`POST /recommend`** (structured intent) → ranked top‑N + reasons + `constraint_status`.  
- **`POST /recommend/nl`** (free text) → parse → calls `/recommend`.  
- **`GET /lots/{id}/spots`** → catalog (stalls, features, neighbors).  
- **`GET /healthz`** → status (model_loaded, profile, db_status, build_sha).

---

## Success Criteria
- Stall F1: **day ≥ 0.90**, **night ≥ 0.80**.  
- Constraint satisfaction ≥ **98%**; Hit@3 ≥ **90%**.  
- Latency p95: `/recommend/nl` ≤ **150 ms**; `/predict/stalls` ≤ **180–200 ms**.  
- One‑command deploy; docs & model card complete.

---

## Risks & Mitigations
- **Night/rain variance:** separate day/night configs; targeted data & augments.  
- **Size confusion:** start with pixel heuristic; add classifier only if needed.  
- **Parser gaps:** grow rule tests to ≥100; keep rules (simple, reliable) this phase.  
- **Timeline crunch:** Franco’s workload lighter; cross‑assist on blockers.