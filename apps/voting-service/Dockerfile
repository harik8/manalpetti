FROM python:3.15
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY templates/ templates/

EXPOSE 8080

CMD ["opentelemetry-instrument","python","app.py"]

