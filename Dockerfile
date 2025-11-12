# Мультистейдж сборка для лёгкого финального образа
FROM python:3.11-slim AS base

# Неинтерактивный режим и отказ от кешей pip
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Установим системные зависимости по минимуму
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Скопируем requirements и установим зависимости
COPY load-test-analizator/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Скопируем приложение
COPY load-test-analizator/app /app/app
COPY load-test-analizator/example.csv /app/example.csv

# Переменные окружения для совместимости с S3 (будут задаваться снаружи)
ENV AWS_ACCESS_KEY_ID="" \
    AWS_SECRET_ACCESS_KEY="" \
    AWS_BUCKET_NAME="" \
    AWS_REGION="" \
    AWS_S3_ENDPOINT="" \
    AWS_S3_FORCE_PATH_STYLE="true"

# Откроем порт сервиса
EXPOSE 8000

# Запуск через uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]