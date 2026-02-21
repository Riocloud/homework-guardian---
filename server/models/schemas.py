"""
Data Models / Schemas
"""

from pydantic import BaseModel, EmailStr
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from enum import Enum


class ActivityType(str, Enum):
    """Activity types detected by AI"""
    STUDYING = "studying"
    IDLE = "idle"
    AWAY = "away"
    PLAYING = "playing"
    DISTRACTED = "distracted"
    UNKNOWN = "unknown"


class AlertType(str, Enum):
    """Alert types"""
    LEAVE_TOO_LONG = "leave_too_long"
    PLAY_WHILE_WORK = "play_while_work"
    SESSION_START = "session_start"
    SESSION_END = "session_end"


# ==================== Request Models ====================

class AnalysisRequest(BaseModel):
    """Metadata from mobile device"""
    session_id: str
    child_id: str
    timestamp: datetime
    activity: ActivityType
    confidence: float
    duration_seconds: int
    location: Optional[str] = None
    device_id: str
    tags: Optional[List[str]] = []


class AlertConfig(BaseModel):
    """Alert configuration"""
    child_id: str
    email: EmailStr
    leave_threshold_minutes: int = 15
    play_while_work_threshold_minutes: int = 5
    enable_email: bool = True
    enable_push: bool = False


# ==================== Response Models ====================

class AnalysisResponse(BaseModel):
    """Analysis result"""
    session_id: str
    activity_summary: Dict[str, int]  # activity: seconds
    total_study_time: int  # seconds
    focus_score: float  # 0-100
    alerts_triggered: List[str]
    timestamp: datetime


class SessionInfo(BaseModel):
    """Session information"""
    session_id: str
    child_id: str
    start_time: datetime
    end_time: Optional[datetime]
    total_duration: int  # seconds
    activities: List[Dict[str, Any]]
    alert_count: int


class ReportResponse(BaseModel):
    """Learning report"""
    child_id: str
    date: str
    total_study_time: int  # seconds
    focus_score: float
    activities: Dict[str, int]
    alerts: List[Dict[str, str]]
    generated_at: datetime
