from fastapi import FastAPI, UploadFile, File, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from typing import List, Optional
import io
import csv
from . import crud, schemas, dashboards, s3_utils
from pathlib import Path
from fastapi.responses import HTMLResponse


BASE_DIR = Path(__file__).resolve().parent
static_path = BASE_DIR / "static"
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))

app = FastAPI(title="Load Test Analysis API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory=static_path), name="static")

@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.post("/upload-csv/")
async def upload_csv(file: UploadFile = File(...)):
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Only CSV files are allowed.")
    content = await file.read()
    decoded = content.decode('utf-8')
    rows = list(csv.DictReader(io.StringIO(decoded)))
    data = crud.parse_csv_data(rows)
    return {"message": f"{len(data)} records processed."}

@app.get("/services/", response_model=List[str])
def get_services():
    return crud.get_services()

@app.get("/stability/", response_model=schemas.StabilityResponse)
def get_stability(service_name: Optional[str] = Query(None)):
    return dashboards.analyze_stability(service_name)

@app.get("/resources/", response_model=schemas.ResourceUsageResponse)
def resource_usage(service_name: Optional[str] = Query(None)):
    return dashboards.resource_usage(service_name)

@app.post("/upload-report-to-s3/")
def upload_report_to_s3():
    file_key = s3_utils.upload_report()
    return {"s3_key": file_key}
