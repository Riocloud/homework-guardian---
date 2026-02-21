"""
Core Configuration
"""

from pydantic_settings import BaseSettings
from typing import Optional
import os


class Settings(BaseSettings):
    """Application settings"""
    
    # App
    APP_NAME: str = "HomeworkGuardian"
    DEBUG: bool = True
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://user:password@postgres:5432/homeworkguardian"
    REDIS_URL: str = "redis://redis:6379/0"
    
    # Email
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    EMAIL_FROM: str = "noreply@homeworkguardian.com"
    
    # Alert thresholds
    ALERT_LEAVE_MINUTES: int = 15
    ALERT_PLAY_WHILE_WORK_MINUTES: int = 5
    
    # GPU
    USE_GPU: bool = True
    
    # Storage
    UPLOAD_DIR: str = "/data/uploads"
    MAX_UPLOAD_SIZE: int = 500 * 1024 * 1024  # 500MB
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()

# Create upload directory
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
