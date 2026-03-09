FROM python:3.12-slim-bookworm
WORKDIR /app

# Install Python dependencies first for better layer caching.
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy the generator script and icon used in the QR center.
COPY qr-generator.py Vinyl_record.png /app/

ENTRYPOINT ["python", "/app/qr-generator.py"]
