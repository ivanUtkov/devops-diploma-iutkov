import sys
from pathlib import Path

# Добавляем корень проекта в sys.path, чтобы можно было импортировать app.*
ROOT_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT_DIR))  # noqa: E402

from app import dashboards, crud  # noqa: E402


def test_analyze_stability():
    # Готовим тестовые данные в том формате, который реально использует приложение
    crud.DATA_STORAGE.clear()
    crud.DATA_STORAGE.extend(
        [
            {
                "timestamp": "2024-01-01T00:00:00",
                "service_name": "service-a",
                "request_count": 100,
                "error_count": 5,
                "response_time_95": 200.0,
                "cpu_usage": 50.0,
                "memory_usage": 256.0,
            },
            {
                "timestamp": "2024-01-01T00:01:00",
                "service_name": "service-a",
                "request_count": 50,
                "error_count": 0,
                "response_time_95": 300.0,
                "cpu_usage": 60.0,
                "memory_usage": 300.0,
            },
        ]
    )

    # Вызываем целевую функцию так же, как её вызывает FastAPI-эндпоинт
    result = dashboards.analyze_stability("service-a")

    # Проверяем тип и базовые поля
    assert result.service_name == "service-a"
    assert result.metrics is not None

    # Ожидаемые значения:
    # total_requests = 100 + 50 = 150
    # total_errors = 5 + 0 = 5
    # error_rate = 5 / 150 = 0.0333...
    # avg_response_time_95 = (200 + 300) / 2_
