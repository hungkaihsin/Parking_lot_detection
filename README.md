# GoPark (Parking Lot Recommender)

> An AI-powered application that helps drivers find the best available parking spots using real-time image analysis, natural language processing, and detailed stall properties (like EV charging, ADA access, and size class). 

## Tech Stack

![Python](https://img.shields.io/badge/Language-Python-3776AB)
![Swift](https://img.shields.io/badge/Language-Swift-F05138)
![SQL](https://img.shields.io/badge/Language-SQL-4479A1)
![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-336791)
![Alembic](https://img.shields.io/badge/Migrations-Alembic-6BA81E)
![SwiftUI](https://img.shields.io/badge/Frontend-SwiftUI-007AFF)
![Vision/NLP](https://img.shields.io/badge/AI-Vision%20%26%20NLP-FF6F00)
![Docker](https://img.shields.io/badge/Infrastructure-Docker-2496ED)

## Key Features

- **Real-time Occupancy:** Analyzes images of parking lots to dynamically detect free or occupied stalls in real-time.
- **Natural Language Spot Matching:** Understands plain English queries (e.g., "Where can I park my SUV?") to recommend the closest and best fitting parking spot.
- **Structured Recommendations:** Accurately matches users with stalls matching critical needs such as EV chargers, ADA compliant spots, or specific vehicle size classes.
- **Dynamic iOS Interactive Map:** Renders an intuitive static image layout overlaid with automatically updating status polygons indicating availability.
- **User Profiling System:** Saves user specifics (like vehicle type) for personalized, automatic smart spotting.

## Results & Performance

- **High Precision Object Detection:** Utilizes YOLOv8-Nano, achieving an exceptional **97.2% mAP@0.5** with an ultra-low inference latency of **5.4 ms**. 
- **Low-Light / Night Optimization:** Custom HSV-augmented models delivered a **5.3-fold increase** in vehicle detection recall in challenging nighttime environments.
- **Lightning Fast NLP:** Our local, rule-based natural language parser achieves a **96% constraint extraction accuracy** with **< 2 ms latency** (approximately 500x faster than traditional LLMs like GPT-4).
- **Sub-50ms End-to-End Latency:** The complete pipeline—spanning raw image ingestion, NLP query parsing, object detection, and recommendation ranking—executes in just **33.96 ms** on average on consumer edge hardware.
- **98% Constraint Satisfaction Rate:** The engine correctly filters and ranks spots meeting all strict user constraints (e.g., ADA accessibility, EV charging, and vehicle size) across rigorous edge-case testing.

## Awards & Recognition 

- **IntelliSys 2026:** Our paper, *"GoPark: An AI-Powered Parking Recommendation System,"* has been officially accepted for presentation and publication at the **Intelligent Systems Conference (IntelliSys) 2026** (September 3–4, 2026 in Amsterdam, The Netherlands). The proceedings will be published in the Springer series *"Lecture Notes in Networks and Systems"*. [Read the full paper here](./docs/Go_park.pdf)

## How to Run

### 1. Backend Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd backend   # IMPORTANT: run all commands from inside the backend folder

# Configure environment variables
cp .env.example .env
# Edit .env and ensure DATABASE_URL uses the Docker service name 'db' if running via Docker:
# DATABASE_URL=postgresql+psycopg2://postgres:password@db:5432/parkinglot

# Start Docker Services (API + PostgreSQL)
docker compose up -d --build

# Initialize Database Schema (Alembic)
docker compose exec api alembic upgrade head
```

The FastAPI server will be running. Open http://127.0.0.1:8000/docs to see the Swagger UI.

### 2. Frontend Setup

1. Open Xcode.
2. Open the project at `frontend/GoPark/GoPark.xcodeproj`.
3. Select an iOS Simulator target (e.g., iPhone 15 Pro).
4. Build and Run the application (`Cmd + R`).

---

## Additional API Setup & Information

<details>
<summary>Click to view detailed Backend API documentation & workflows</summary>

### API Endpoints

#### System Health
- **`GET /healthz`**: Checks the operational status of the API, database, and machine learning model.

#### Parking Lot Management
- **`GET /lots/{lot_id}/spots`**: Retrieves a detailed list of all parking stalls for a given `lot_id`, including their geometry and features.
- **`POST /lots/{lot_id}/predict`**: Analyzes an uploaded image of a parking lot to detect occupied stalls, updates their state in the DB, and logs vehicle events.

#### Recommendations
- **`POST /recommend`**: Recommends the best available parking stalls based on structured criteria or a natural language query.
  - *Natural Language Query*: `{"query": "I need a spot for my truck, preferably buffered"}`
  - *Structured Request*: `{"is_ev": true, "connector": "J1772", "size_class": 2, "buffered": true}`
- **`POST /chat`**: A stub endpoint for conversational recommendations.

### Daily Workflow
1. **Start services**: `docker compose up -d`
2. **Run migrations**:
   ```bash
   docker compose exec api alembic revision --autogenerate -m "update schema"
   docker compose exec api alembic upgrade head
   ```
3. **Tail API logs**: `docker compose logs -f api`
4. **Stop services**: `docker compose down` (Add `-v` to wipe DB data).

</details>

## Contact & Authors

This project was collaboratively built by:
- **Kai-Hsin (Daniel) Hung** - k_hung2@u.pacific.edu | [LinkedIn](https://www.linkedin.com/in/kai-hsin-hung/)
- **Gia Huy (Jerry) Phung** - g_phung@u.pacific.edu | [LinkedIn](https://www.linkedin.com/in/huy-phung-gia/)
- **Franco Lorenzino** - f_lorenzino@u.pacific.edu | [LinkedIn](https://www.linkedin.com/in/franco-lorenzino-05721b209/)
