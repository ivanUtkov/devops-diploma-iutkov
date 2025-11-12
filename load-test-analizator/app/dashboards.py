from typing import Optional
from .crud import DATA_STORAGE
from .schemas import StabilityResponse, StabilityMetrics, ResourceUsageResponse, ResourceUsageEntry

def analyze_stability(service_name: Optional[str]) -> StabilityResponse:
    filtered = [d for d in DATA_STORAGE if (service_name is None or d["service_name"] == service_name)]
    total_requests = sum(d["request_count"] for d in filtered)
    total_errors = sum(d["error_count"] for d in filtered)
    avg_response_time = 0.0
    if filtered:
        avg_response_time = sum(d["response_time_95"] for d in filtered) / len(filtered)
    error_rate = (total_errors / total_requests) if total_requests > 0 else 0
    return StabilityResponse(
        service_name=service_name,
        metrics=StabilityMetrics(
            error_rate=error_rate,
            avg_response_time_95=avg_response_time
        )
    )

def resource_usage(service_name: Optional[str]) -> ResourceUsageResponse:
    filtered = [d for d in DATA_STORAGE if (service_name is None or d["service_name"] == service_name)]
    usage = [
        ResourceUsageEntry(timestamp=d["timestamp"], cpu_usage=d["cpu_usage"], memory_usage=d["memory_usage"])
        for d in filtered
    ]
    return ResourceUsageResponse(service_name=service_name, usage=usage)
