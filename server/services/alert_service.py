"""
Alert Service - Monitor and trigger alerts
"""

import logging
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
from collections import defaultdict

from models.schemas import AlertConfig, AlertType
from services.email_service import EmailService

logger = logging.getLogger(__name__)


class AlertService:
    """Alert monitoring and triggering service"""
    
    def __init__(self):
        self.email_service = EmailService()
        # In production, this would be in database
        self.configs: Dict[str, AlertConfig] = {}
        self.session_states: Dict[str, Dict[str, Any]] = defaultdict(dict)
        
    async def update_config(self, config: AlertConfig):
        """
        Update alert configuration for a child
        """
        self.configs[config.child_id] = config
        logger.info(f"Alert config updated for {config.child_id}")
        
    async def get_status(self, session_id: str) -> Dict[str, Any]:
        """
        Get current alert status for a session
        """
        state = self.session_states.get(session_id, {})
        return {
            "session_id": session_id,
            "is_active": state.get("is_active", False),
            "leave_time": state.get("leave_time"),
            "play_time": state.get("play_time"),
            "alerts_sent": state.get("alerts_sent", [])
        }
    
    async def check_and_trigger(
        self,
        session_id: str,
        child_id: str,
        activity: str,
        duration_seconds: int
    ) -> List[str]:
        """
        Check activity and trigger alerts if needed
        """
        alerts_triggered = []
        
        if child_id not in self.configs:
            return alerts_triggered
            
        config = self.configs[child_id]
        state = self.session_states[session_id]
        
        # Check for leave alert
        if activity == "away":
            leave_time = state.get("leave_time")
            if leave_time is None:
                state["leave_time"] = datetime.now()
                state["leave_duration"] = duration_seconds
            else:
                # Update duration
                state["leave_duration"] = state.get("leave_duration", 0) + duration_seconds
                
                # Check threshold
                leave_minutes = state["leave_duration"] / 60
                if leave_minutes >= config.leave_threshold_minutes:
                    if "leave_too_long" not in state.get("alerts_sent", []):
                        await self._send_alert(
                            config,
                            AlertType.LEAVE_TOO_LONG,
                            session_id,
                            f"离开时间: {leave_minutes:.0f} 分钟"
                        )
                        alerts_triggered.append("leave_too_long")
                        state.setdefault("alerts_sent", []).append("leave_too_long")
        else:
            # Reset leave time
            state["leave_time"] = None
            state["leave_duration"] = 0
            
        # Check for play while working alert
        if activity == "playing" or activity == "distracted":
            play_time = state.get("play_time")
            if play_time is None:
                state["play_time"] = datetime.now()
                state["play_duration"] = duration_seconds
            else:
                state["play_duration"] = state.get("play_duration", 0) + duration_seconds
                
                play_minutes = state["play_duration"] / 60
                if play_minutes >= config.play_while_work_threshold_minutes:
                    if "play_while_work" not in state.get("alerts_sent", []):
                        await self._send_alert(
                            config,
                            AlertType.PLAY_WHILE_WORK,
                            session_id,
                            f"玩耍时间: {play_minutes:.0f} 分钟"
                        )
                        alerts_triggered.append("play_while_work")
                        state.setdefault("alerts_sent", []).append("play_while_work")
        else:
            # Reset play time
            state["play_time"] = None
            state["play_duration"] = 0
            
        return alerts_triggered
    
    async def _send_alert(
        self,
        config: AlertConfig,
        alert_type: AlertType,
        session_id: str,
        details: str
    ):
        """
        Send alert notification
        """
        if config.enable_email:
            await self.email_service.send_alert(
                config.email,
                alert_type.value,
                config.child_id,
                details
            )
            logger.info(f"Alert sent: {alert_type.value} for {config.child_id}")
    
    async def start_session(self, session_id: str, child_id: str):
        """
        Start monitoring a session
        """
        self.session_states[session_id] = {
            "child_id": child_id,
            "is_active": True,
            "start_time": datetime.now(),
            "leave_time": None,
            "play_time": None,
            "alerts_sent": []
        }
        
        # Send session start notification
        if child_id in self.configs:
            config = self.configs[child_id]
            if config.enable_email:
                await self.email_service.send_alert(
                    config.email,
                    AlertType.SESSION_START,
                    child_id,
                    "学习监控已启动"
                )
                
    async def end_session(self, session_id: str):
        """
        End monitoring a session
        """
        if session_id in self.session_states:
            child_id = self.session_states[session_id]["child_id"]
            self.session_states[session_id]["is_active"] = False
            
            # Send session end notification
            if child_id in self.configs:
                config = self.configs[child_id]
                if config.enable_email:
                    await self.email_service.send_alert(
                        config.email,
                        AlertType.SESSION_END,
                        child_id,
                        "今日学习已结束"
                    )
