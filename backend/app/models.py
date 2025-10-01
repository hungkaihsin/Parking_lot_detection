from sqlalchemy import (
    Column, String, Float, Boolean, Text, TIMESTAMP, BigInteger,
    Integer, ForeignKey, JSON, Table
)
from sqlalchemy.orm import relationship
from .db import Base
import datetime

# Association Table for Neighbors (Many-to-Many self-referential)
stall_neighbors = Table(
    'stall_neighbors', Base.metadata,
    Column('stall_id', String, ForeignKey('stalls.id'), primary_key=True),
    Column('neighbor_id', String, ForeignKey('stalls.id'), primary_key=True)
)

class Stall(Base):
    __tablename__ = "stalls"
    id = Column(String, primary_key=True)  # e.g., "A-27"
    lot_id = Column(String, nullable=False, default="LotA")
    geom_wkt = Column(Text, nullable=False)
    center_x = Column(Float)
    center_y = Column(Float)

    # Relationships
    features = relationship("StallFeature", back_populates="stall", uselist=False, cascade="all, delete-orphan")
    events = relationship("Event", back_populates="stall")
    
    # Many-to-many relationship for neighbors
    neighbors = relationship(
        "Stall",
        secondary=stall_neighbors,
        primaryjoin=id == stall_neighbors.c.stall_id,
        secondaryjoin=id == stall_neighbors.c.neighbor_id,
        backref="neighbor_of"
    )


class StallFeature(Base):
    __tablename__ = "stall_features"
    id = Column(String, ForeignKey("stalls.id"), primary_key=True)
    is_ev = Column(Boolean, default=False)
    is_ada = Column(Boolean, default=False)
    connectors = Column(String)  # e.g., "J1772, NACS"
    width_class = Column(Integer) # e.g., 1 (compact), 2 (standard), 3 (wide)
    dist_to_entrance = Column(Float)

    # Relationship
    stall = relationship("Stall", back_populates="features")


class Event(Base):
    __tablename__ = "events"
    id = Column(Integer, primary_key=True, autoincrement=True)
    stall_id = Column(String, ForeignKey("stalls.id"), nullable=False)
    ts = Column(TIMESTAMP, default=datetime.datetime.utcnow)
    event_type = Column(String, nullable=False) # e.g., "occupy", "vacate"
    
    # Relationship
    stall = relationship("Stall", back_populates="events")

# --- Keeping other models for now, can be removed if not needed ---

# 3) Runs
class Run(Base):
    __tablename__ = "runs"
    run_id = Column(String, primary_key=True)   # UUID
    lot_id = Column(String, nullable=False)
    video_path = Column(String)
    started_at = Column(TIMESTAMP, nullable=False)
    ended_at = Column(TIMESTAMP)

# 4) Spot Status
class SpotStatus(Base):
    __tablename__ = "spot_status"
    run_id = Column(String, ForeignKey("runs.run_id"), primary_key=True)
    ts_ms = Column(BigInteger, primary_key=True)
    # Changed ForeignKey to stalls.id
    spot_id = Column(String, ForeignKey("stalls.id"), primary_key=True)
    state = Column(String, nullable=False)      # FREE or TAKEN

# 5) Detections
class Detection(Base):
    __tablename__ = "detections"
    det_id = Column(Integer, primary_key=True, autoincrement=True)
    run_id = Column(String, ForeignKey("runs.run_id"))
    ts_ms = Column(BigInteger)
    x1 = Column(Float)
    y1 = Column(Float)
    x2 = Column(Float)
    y2 = Column(Float)
    conf = Column(Float)
    cls = Column(String)

# 6) Car Specs
class CarSpec(Base):
    __tablename__ = "carspecs"
    make = Column(String, primary_key=True)
    model = Column(String, primary_key=True)
    year = Column(Integer, primary_key=True)
    size_class = Column(String)
    length_mm = Column(Integer)
    width_mm = Column(Integer)
    height_mm = Column(Integer)

# 7) Model Registry
class ModelRegistry(Base):
    __tablename__ = "models"
    name = Column(String, primary_key=True)
    path = Column(String)
    metrics_json = Column(JSON)
    created_at = Column(TIMESTAMP)