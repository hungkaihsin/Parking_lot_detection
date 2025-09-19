from logging.config import fileConfig
import os

from sqlalchemy import engine_from_config, pool
from alembic import context

# Import models Base
from app.db import Base

# Load .env file
from dotenv import load_dotenv
load_dotenv()

# -----------------------------------------------------------------------------
# Alembic Config
# -----------------------------------------------------------------------------
config = context.config

# Get DB URL from .env (fallback if missing)
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg2://postgres:password@localhost:5432/parkinglot"
)

# Inject DB URL into Alembic config
config.set_main_option("sqlalchemy.url", DATABASE_URL)

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Models metadata
target_metadata = Base.metadata

# -----------------------------------------------------------------------------
# Migration Runners
# -----------------------------------------------------------------------------
def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode (no live DB connection)."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode (with live DB)."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()