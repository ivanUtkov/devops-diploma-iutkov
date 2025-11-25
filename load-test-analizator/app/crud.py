from typing import List, Dict
DATA_STORAGE = []


def parse_csv_data(rows: List[Dict]) -> List[Dict]:
    DATA_STORAGE.clear()
    for r in rows:
        DATA_STORAGE.append({
            "timestamp": r["timestamp"],
            "service_name": r["service_name"],
            "request_count": int(r["request_count"]),
            "error_count": int(r["error_count"]),
            "response_time_95": float(r["response_time_95"]),
            "cpu_usage": float(r["cpu_usage"]),
            "memory_usage": float(r["memory_usage"])
        })
    return DATA_STORAGE


def get_services() -> List[str]:
    return list({d["service_name"] for d in DATA_STORAGE})
