
import os
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import pytest

# Set up the test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Override the get_db dependency to use the test database
from app.main import app, get_db

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

@pytest.fixture(scope="module", autouse=True)
def setup_and_teardown():
    # Setup: create a dummy model file for the test
    os.makedirs("models", exist_ok=True)
    with open("models/yolo_day.pt", "w") as f:
        f.write("dummy model")
    with open("models/yolo_night.pt", "w") as f:
        f.write("dummy model")
    
    yield
    
    # Teardown: clean up the dummy files and test database
    os.remove("models/yolo_day.pt")
    os.remove("models/yolo_night.pt")
    if os.path.exists("test.db"):
        os.remove("test.db")

def test_healthz_endpoint():
    """
    Tests the /healthz endpoint for a successful response and correct structure.
    """
    response = client.get("/healthz")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "db_status" in data
    assert "model_loaded" in data
    assert "profile" in data
    assert "build_sha" in data
    assert data["db_status"] == "ok"

def test_healthz_profile_day():
    """
    Tests if the /healthz endpoint correctly reports the 'day' profile.
    """
    os.environ["PROFILE"] = "day"
    # We need to reload the app to pick up the new env var
    from importlib import reload
    from app import main, config
    reload(config)
    reload(main)
    
    # Create a new client to test the reloaded app
    client = TestClient(main.app)
    app.dependency_overrides[get_db] = override_get_db # re-apply override
    
    response = client.get("/healthz")
    assert response.status_code == 200
    data = response.json()
    assert data["profile"] == "day"
    assert data["model_loaded"] == True

def test_healthz_profile_night():
    """
    Tests if the /healthz endpoint correctly reports the 'night' profile.
    """
    os.environ["PROFILE"] = "night"
    from importlib import reload
    from app import main, config
    reload(config)
    reload(main)

    client = TestClient(main.app)
    app.dependency_overrides[get_db] = override_get_db # re-apply override

    response = client.get("/healthz")
    assert response.status_code == 200
    data = response.json()
    assert data["profile"] == "night"
    assert data["model_loaded"] == True

def test_healthz_model_not_loaded():
    """
    Tests if the /healthz endpoint reports when a model file is missing.
    """
    os.environ["PROFILE"] = "nonexistent"
    from importlib import reload
    from app import main, config
    reload(config)
    reload(main)

    client = TestClient(main.app)
    app.dependency_overrides[get_db] = override_get_db # re-apply override

    response = client.get("/healthz")
    assert response.status_code == 200
    data = response.json()
    assert data["profile"] == "nonexistent"
    assert data["model_loaded"] == False
    assert data["status"] == "degraded"
