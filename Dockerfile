# Base image with Python 3.12
FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Add uv venv location to path
ENV PATH="/app/.venv/bin:$PATH"

# Copy UV from official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy dependency files and README (required for build)
COPY pyproject.toml uv.lock README.md ./

# Install dependencies using UV
RUN uv sync --frozen --no-cache

# Copy application code
COPY ./src ./src

# Expose port
EXPOSE 8080

# Run the application
CMD ["uvicorn", "src.app:app", "--host", "0.0.0.0", "--port", "8080"]
