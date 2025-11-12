from pydantic import BaseModel
from typing import List, Optional

class StabilityMetrics(BaseModel):
    error_rate: float
    avg_response_time_95: float

class StabilityResponse(BaseModel):
    service_name: Optional[str]
    metrics: StabilityMetrics

class ResourceUsageEntry(BaseModel):
    timestamp: str
    cpu_usage: float
    memory_usage: float

class ResourceUsageResponse(BaseModel):
    service_name: Optional[str]
    usage: List[ResourceUsageEntry]
