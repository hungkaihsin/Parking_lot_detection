FROM python:3.12-slim

ARG GIT_SHA
ENV GIT_SHA=${GIT_SHA}

# OS deps (psycopg2 + optional pg_isready)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    build-essential \
    libpq-dev \
    postgresql-client \
    libgl1 \
    git \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV PYTHONPATH /app
# Install Python deps first (cache-friendly)
COPY requirements.txt ./
# Install CPU-only PyTorch to avoid downloading huge GPU binaries
RUN pip install "torch==2.8.0" torchvision --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir -r requirements.txt

# Copy app
COPY . .

# Fix Windows line endings and make start.sh executable
RUN sed -i 's/\r$//' /app/start.sh && chmod +x /app/start.sh

# Non-root (optional)
RUN useradd -ms /bin/bash appuser
USER appuser

CMD ["bash", "/app/start.sh"]
