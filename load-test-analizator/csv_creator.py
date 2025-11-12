import csv
from datetime import datetime, timedelta
import random

filename = "load_test_data.csv"

header = ["timestamp", "service_name", "request_count", "error_count", "response_time_95", "cpu_usage", "memory_usage"]

services = ["auth", "payment", "search", "profile"]

start_time = datetime.now() - timedelta(hours=1)

rows = []
for i in range(60):  # 60 минут
    timestamp = (start_time + timedelta(minutes=i)).strftime("%Y-%m-%d %H:%M:%S")
    for service in services:
        request_count = random.randint(100, 500)
        error_count = random.randint(0, 10)
        response_time_95 = round(random.uniform(100, 500), 2)  # ms
        cpu_usage = round(random.uniform(20, 90), 2)          # %
        memory_usage = round(random.uniform(1000, 4000), 2)   # MB
        rows.append([timestamp, service, request_count, error_count, response_time_95, cpu_usage, memory_usage])

with open(filename, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(header)
    writer.writerows(rows)

print(f"CSV file '{filename}' created with {len(rows)} rows.")
