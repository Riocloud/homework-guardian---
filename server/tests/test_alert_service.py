"""
Unit Tests for Alert Service
"""

import pytest
from datetime import datetime
from services.alert_service import AlertService
from models.schemas import AlertConfig, AlertType
from pydantic import EmailStr


class TestAlertService:
    """Test alert monitoring and triggering"""
    
    @pytest.fixture
    def alert_service(self):
        """Create alert service instance"""
        return AlertService()
    
    @pytest.fixture
    def sample_config(self):
        """Create sample alert config"""
        return AlertConfig(
            child_id="child_001",
            email=EmailStr("parent@example.com"),
            leave_threshold_minutes=15,
            play_while_work_threshold_minutes=5,
            enable_email=False  # Disable email for testing
        )
    
    @pytest.mark.asyncio
    async def test_update_config(self, alert_service, sample_config):
        """Test updating alert configuration"""
        await alert_service.update_config(sample_config)
        assert sample_config.child_id in alert_service.configs
        
    @pytest.mark.asyncio
    async def test_session_start(self, alert_service, sample_config):
        """Test starting a monitoring session"""
        await alert_service.update_config(sample_config)
        await alert_service.start_session("session_001", "child_001")
        
        state = alert_service.session_states["session_001"]
        assert state["is_active"] == True
        assert state["child_id"] == "child_001"
        
    @pytest.mark.asyncio
    async def test_session_end(self, alert_service, sample_config):
        """Test ending a monitoring session"""
        await alert_service.update_config(sample_config)
        await alert_service.start_session("session_001", "child_001")
        await alert_service.end_session("session_001")
        
        state = alert_service.session_states["session_001"]
        assert state["is_active"] == False
        
    @pytest.mark.asyncio
    async def test_leave_alert_trigger(self, alert_service, sample_config):
        """Test that leave alert triggers after threshold"""
        # Set lower threshold for testing
        sample_config.leave_threshold_minutes = 1
        await alert_service.update_config(sample_config)
        await alert_service.start_session("session_001", "child_001")
        
        # Simulate away activity for 70 seconds (> 1 minute threshold)
        alerts = await alert_service.check_and_trigger(
            "session_001", "child_001", "away", 70
        )
        
        assert "leave_too_long" in alerts
        
    @pytest.mark.asyncio
    async def test_play_while_work_alert(self, alert_service, sample_config):
        """Test that play-while-working alert triggers"""
        # Set lower threshold for testing
        sample_config.play_while_work_threshold_minutes = 1
        await alert_service.update_config(sample_config)
        await alert_service.start_session("session_001", "child_001")
        
        # Simulate playing for 70 seconds
        alerts = await alert_service.check_and_trigger(
            "session_001", "child_001", "playing", 70
        )
        
        assert "play_while_work" in alerts
        
    @pytest.mark.asyncio
    async def test_no_alert_below_threshold(self, alert_service, sample_config):
        """Test that no alert triggers below threshold"""
        sample_config.leave_threshold_minutes = 15
        await alert_service.update_config(sample_config)
        await alert_service.start_session("session_001", "child_001")
        
        # Simulate away for only 5 minutes (threshold is 15)
        alerts = await alert_service.check_and_trigger(
            "session_001", "child_001", "away", 300  # 5 minutes
        )
        
        assert "leave_too_long" not in alerts
        
    @pytest.mark.asyncio
    async def test_reset_leave_on_return(self, alert_service, sample_config):
        """Test that leave timer resets when child returns"""
        sample_config.leave_threshold_minutes = 1
        await alert_service.update_config(sample_config)
        await alert_service.start_session("session_001", "child_001")
        
        # Trigger leave alert
        await alert_service.check_and_trigger("session_001", "child_001", "away", 70)
        
        # Child returns to studying
        await alert_service.check_and_trigger("session_001", "child_001", "studying", 10)
        
        # Leave time should be reset
        state = alert_service.session_states["session_001"]
        assert state.get("leave_time") is None


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
