from sqlalchemy import Column, Integer, Float, DateTime
from sqlalchemy.orm import declarative_base
from datetime import datetime
import pytz

Base = declarative_base()

class EnergyReading(Base):
    __tablename__ = "energy_readings"
    id = Column(Integer, primary_key=True, index=True)
    voltage = Column(Float, nullable=False)
    current = Column(Float, nullable=False)
    power = Column(Float, nullable=False)
    kwh = Column(Float, nullable=False)
    timestamp = Column(DateTime, default=lambda: datetime.now(pytz.timezone("Asia/Manila")))
