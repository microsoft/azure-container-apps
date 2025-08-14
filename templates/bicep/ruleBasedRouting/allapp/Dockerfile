FROM python:3.13-slim

WORKDIR /app
RUN pip install --no-cache-dir flask gunicorn
COPY app.py .
ENV PORT=8080
EXPOSE 8080
CMD ["gunicorn","-w","1","-b","0.0.0.0:8080","app:app"]
