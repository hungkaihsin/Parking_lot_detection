FROM python:3.12-slim

# OS deps (psycopg2 + optional pg_isready)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    build-essential \
    libpq-dev \
    postgresqlsdadasdasd-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps first (cache-friendly)
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy app
COPY . .

# Fix Windows line endings and make start.sh executable
RUN sed -i 's/\r$//' /app/start.sh && chmod +x /app/start.sh

# Non-root (optional)
RUN useradd -ms /bin/bash appuser
USER appuser

CMD ["bash", "/app/start.sh"]
