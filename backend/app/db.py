# app/db.py
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base, joinedload
import datetime

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./local.db")

Base = declarative_base()
_engine = None
_SessionLocal = None

# In-memory cache for the stall catalog
_stall_catalog_cache = None
_cache_expiry = None
CACHE_DURATION = datetime.timedelta(minutes=5)

def get_engine():
    global _engine
    if _engine is None:
        _engine = create_engine(DATABASE_URL, pool_pre_ping=True, future=True)
    return _engine

def get_sessionmaker():
    global _SessionLocal
    if _SessionLocal is None:
        _SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=get_engine(), future=True)
    return _SessionLocal

def get_db():
    db = get_sessionmaker()()
    try:
        yield db
    finally:
        db.close()

def get_cached_stall_catalog(db_session):
    """
    Returns the stall catalog from cache if available and not expired,
    otherwise fetches it from the database and caches it.
    """
    from . import models # Import moved here
    global _stall_catalog_cache, _cache_expiry
    now = datetime.datetime.utcnow()

    if _stall_catalog_cache is None or _cache_expiry is None or now > _cache_expiry:
        # Cache is invalid, fetch from DB
        _stall_catalog_cache = (
            db_session.query(models.Stall)
            .options(joinedload(models.Stall.features))
            .filter(models.Stall.is_occupied == False)
            .all()
        )
        _cache_expiry = now + CACHE_DURATION
    
    return _stall_catalog_cache
