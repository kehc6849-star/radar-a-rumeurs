FROM python:3.12-slim

# Do not write .pyc files and do not buffer logs.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# Run as a normal user, not as root.
RUN useradd --create-home radar
USER radar

# The hosting platform usually provides the PORT variable.
CMD ["sh", "-c", "uvicorn app.main:application --host 0.0.0.0 --port ${PORT:-8000}"]
