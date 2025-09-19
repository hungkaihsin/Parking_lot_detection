from sqlalchemy import Column, String, Float, Boolean, Text, TIMESTAMP, BigInteger, Integer, ForeignKey, JSON
from .db import Base

# 1) Parking Spots
class Spot(Base):
    __tablename__ = "spots"
    id = Column(String, primary_key=True)       # "A-27" or UUID
    lot_id = Column(String, nullable=False, default="LotA")
    row = Column(String)
    geom_wkt = Column(Text, nullable=False)
    center_x = Column(Float)
    center_y = Column(Float)
    ev = Column(Boolean, default=False)
    connector = Column(String)
    power_kw = Column(Float)
    ada = Column(Boolean, default=False)

# 2) Neighbors
class SpotNeighbor(Base):
    __tablename__ = "spot_neighbors"
    spot_id = Column(String, ForeignKey("spots.id"), primary_key=True)
    left_id = Column(String, ForeignKey("spots.id"))
    right_id = Column(String, ForeignKey("spots.id"))

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
    spot_id = Column(String, ForeignKey("spots.id"), primary_key=True)
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