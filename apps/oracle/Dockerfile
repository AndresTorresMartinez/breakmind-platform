FROM python:3.11-slim

WORKDIR /app

COPY apps/oracle/pyproject.toml .

RUN pip install --no-cache-dir uv && uv pip install --system -e .

COPY apps/oracle . 

EXPOSE 8000

CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
