const API_BASE = window.location.origin;

async function fetchServices() {
    const res = await fetch(`${API_BASE}/services/`);
    const services = await res.json();
    const select = document.getElementById("service-select");
    select.innerHTML = '<option value="">All Services</option>';
    services.forEach(s => {
        const option = document.createElement("option");
        option.value = s;
        option.text = s;
        select.appendChild(option);
    });
}
async function fetchStability(service) {
    const url = new URL(`${API_BASE}/stability/`);
    if (service) url.searchParams.set("service_name", service);
    const res = await fetch(url);
    const data = await res.json();
    const div = document.getElementById("stability-summary");
    div.innerHTML = `
        <h2>Stability & Reliability</h2>
        <p>Error Rate: ${(data.metrics.error_rate * 100).toFixed(2)}%</p>
        <p>95th Percentile Response Time: ${data.metrics.avg_response_time_95.toFixed(2)} ms</p>
    `;
}

let cpuChart, memoryChart;
async function fetchResourceUsage(service) {
    const url = new URL(`${API_BASE}/resources/`);
    if (service) url.searchParams.set("service_name", service);
    const res = await fetch(url);
    const data = await res.json();

    const timestamps = data.usage.map(u => u.timestamp);
    const cpuData = data.usage.map(u => u.cpu_usage);
    const memoryData = data.usage.map(u => u.memory_usage);

    if(cpuChart) cpuChart.destroy();
    if(memoryChart) memoryChart.destroy();

    const ctxCpu = document.getElementById('cpuChart').getContext('2d');
    cpuChart = new Chart(ctxCpu, {
        type: 'line',
        data: {
            labels: timestamps,
            datasets: [{
                label: 'CPU Usage (%)',
                data: cpuData,
                borderColor: 'blue',
                fill: false
            }]
        }
    });

    const ctxMemory = document.getElementById('memoryChart').getContext('2d');
    memoryChart = new Chart(ctxMemory, {
        type: 'line',
        data: {
            labels: timestamps,
            datasets: [{
                label: 'Memory Usage (MB)',
                data: memoryData,
                borderColor: 'green',
                fill: false
            }]
        }
    });
}

document.getElementById("service-select").addEventListener("change", (e) => {
    const service = e.target.value;
    fetchStability(service);
    fetchResourceUsage(service);
});

window.onload = async () => {
    await fetchServices();
    await fetchStability();
    await fetchResourceUsage();
};

document.getElementById("upload-form").addEventListener("submit", async (event) => {
    event.preventDefault();
    const statusElem = document.getElementById("upload-status");
    statusElem.textContent = "Uploading...";
    const fileInput = document.getElementById("csv-file");
    if (fileInput.files.length === 0) {
        statusElem.textContent = "Please select a CSV file.";
        return;
    }
    const file = fileInput.files[0];
    const formData = new FormData();
    formData.append("file", file);

    try {
        const response = await fetch("http://localhost:8000/upload-csv/", {
            method: "POST",
            body: formData,
        });
        if (!response.ok) {
            const errorData = await response.json();
            statusElem.textContent = `Upload failed: ${errorData.detail || response.statusText}`;
            return;
        }
        const data = await response.json();
        statusElem.textContent = data.message || "Upload successful!";
        
        // Обновим сервисы и графики после загрузки
        await fetchServices();
        await fetchStability();
        await fetchResourceUsage();
    } catch (error) {
        statusElem.textContent = `Upload failed: ${error.message}`;
    }
});
