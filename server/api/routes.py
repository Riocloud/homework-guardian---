"""
API Routes for HomeworkGuardian
"""

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from typing import List, Optional
from datetime import datetime, timedelta
from pydantic import BaseModel
import logging
import json

from services.analysis_service import AnalysisService
from services.email_service import EmailService
from services.alert_service import AlertService
from models.schemas import (
    AnalysisRequest,
    AnalysisResponse,
    SessionInfo,
    AlertConfig,
    ReportResponse
)

logger = logging.getLogger(__name__)
router = APIRouter()

# Service instances
analysis_service = AnalysisService()
email_service = EmailService()
alert_service = AlertService()


# ==================== Upload Endpoints ====================

@router.post("/upload/metadata")
async def upload_metadata(request: AnalysisRequest):
    """
    Receive metadata from mobile device
    """
    try:
        result = await analysis_service.process_metadata(request)
        return {"status": "success", "data": result}
    except Exception as e:
        logger.error(f"Error processing metadata: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/upload/video")
async def upload_video(
    video: UploadFile = File(...),
    session_id: Optional[str] = None,
    timestamp: Optional[str] = None
):
    """
    Upload video segment from mobile device
    """
    try:
        result = await analysis_service.process_video(
            video, 
            session_id=session_id,
            timestamp=timestamp
        )
        return {"status": "success", "data": result}
    except Exception as e:
        logger.error(f"Error processing video: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Analysis Endpoints ====================

@router.post("/analysis/segment")
async def analyze_segment(
    session_id: str,
    start_time: datetime,
    end_time: datetime
):
    """
    Analyze a specific time segment
    """
    try:
        result = await analysis_service.analyze_time_segment(
            session_id,
            start_time,
            end_time
        )
        return {"status": "success", "data": result}
    except Exception as e:
        logger.error(f"Error analyzing segment: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/analysis/session/{session_id}")
async def get_session_analysis(session_id: str):
    """
    Get full analysis for a session
    """
    try:
        result = await analysis_service.get_session_summary(session_id)
        return {"status": "success", "data": result}
    except Exception as e:
        logger.error(f"Error getting session: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Alert Endpoints ====================

@router.post("/alert/config")
async def set_alert_config(config: AlertConfig):
    """
    Set alert thresholds
    """
    try:
        await alert_service.update_config(config)
        return {"status": "success", "message": "Alert config updated"}
    except Exception as e:
        logger.error(f"Error updating alert config: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/alert/status/{session_id}")
async def get_alert_status(session_id: str):
    """
    Get current alert status for a session
    """
    try:
        status = await alert_service.get_status(session_id)
        return {"status": "success", "data": status}
    except Exception as e:
        logger.error(f"Error getting alert status: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Report Endpoints ====================

@router.get("/report/daily/{child_id}")
async def get_daily_report(
    child_id: str,
    date: Optional[str] = None
):
    """
    Get daily learning report
    """
    try:
        report = await analysis_service.generate_daily_report(child_id, date)
        return {"status": "success", "data": report}
    except Exception as e:
        logger.error(f"Error generating daily report: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/report/weekly/{child_id}")
async def get_weekly_report(child_id: str):
    """
    Get weekly learning report
    """
    try:
        report = await analysis_service.generate_weekly_report(child_id)
        return {"status": "success", "data": report}
    except Exception as e:
        logger.error(f"Error generating weekly report: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Email Endpoints ====================

@router.post("/email/test")
async def test_email(recipient: str):
    """
    Send test email
    """
    try:
        await email_service.send_test_email(recipient)
        return {"status": "success", "message": "Test email sent"}
    except Exception as e:
        logger.error(f"Error sending test email: {e}")
        raise HTTPException(status_code=500, detail=str(e))
