FROM python:3.12-slim

WORKDIR /app

COPY app/app.py ./app.py

ENV PORT=5000

EXPOSE 5000

RUN useradd --uid 10001 appuser

USER appuser

CMD ["python", "app.py"]