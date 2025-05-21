from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import pytz

app = FastAPI()


energy_log = []

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class EnergyData(BaseModel):
    voltage: float
    current: float
    power: float
    kwh: float

@app.post("/data")
async def receive_data(data: EnergyData):
    print("Received data:", data)
    entry = data.dict()
    entry["id"] = len(energy_log) + 1
    entry["timestamp"] = datetime.now(pytz.timezone("Asia/Manila")).isoformat()
    energy_log.append(entry)
    return {"status": "success", "data": entry}

@app.get("/data")
async def get_data():
    return energy_log[-10:]
