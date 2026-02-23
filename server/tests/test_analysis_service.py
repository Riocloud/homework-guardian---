"""
Unit Tests for Analysis Service
"""

import pytest
from datetime import datetime

# Skip if analysis service dependencies (cv2, etc.) are not available
pytest.importorskip("cv2")
from services.analysis_service import AnalysisService


class TestAnalysisService:
    """Test analysis service functionality"""

    @pytest.fixture
    def analysis_service(self):
        """Create analysis service instance"""
        return AnalysisService()

    @pytest.mark.asyncio
    async def test_process_metadata_returns_dict(self, analysis_service):
        """Test that process_metadata returns expected structure"""
        class FakeRequest:
            session_id = "session_001"
            activity = "studying"
            confidence = 0.9

        result = await analysis_service.process_metadata(FakeRequest())
        assert isinstance(result, dict)
        assert result["session_id"] == "session_001"
        assert result["received"] is True
        assert "gpu_processed" in result

    @pytest.mark.asyncio
    async def test_process_video_returns_dict(self, analysis_service):
        """Test that process_video returns expected structure"""
        result = await analysis_service.process_video(
            None, session_id="session_001", timestamp="2026-02-21T10:00:00"
        )
        assert isinstance(result, dict)
        assert result["session_id"] == "session_001"
        assert result["video_received"] is True
        assert "gpu_processed" in result

    @pytest.mark.asyncio
    async def test_analyze_time_segment(self, analysis_service):
        """Test time segment analysis returns correct duration"""
        start = datetime(2026, 2, 21, 10, 0, 0)
        end = datetime(2026, 2, 21, 10, 30, 0)

        result = await analysis_service.analyze_time_segment(
            "session_001", start, end
        )

        assert result["session_id"] == "session_001"
        assert result["duration_seconds"] == 1800
        assert "activities" in result
        assert "focus_score" in result
        assert result["focus_score"] >= 0 and result["focus_score"] <= 100

    @pytest.mark.asyncio
    async def test_get_session_summary(self, analysis_service):
        """Test session summary structure"""
        result = await analysis_service.get_session_summary("session_001")

        assert result["session_id"] == "session_001"
        assert "total_duration" in result
        assert "activities" in result
        assert "focus_score" in result
        assert isinstance(result["activities"], dict)

    @pytest.mark.asyncio
    async def test_generate_daily_report(self, analysis_service):
        """Test daily report generation"""
        result = await analysis_service.generate_daily_report(
            "child_001", date="2026-02-21"
        )

        assert result["child_id"] == "child_001"
        assert result["date"] == "2026-02-21"
        assert "total_study_time" in result
        assert "focus_score" in result
        assert "alerts" in result
        assert isinstance(result["alerts"], list)

    @pytest.mark.asyncio
    async def test_generate_weekly_report(self, analysis_service):
        """Test weekly report generation"""
        result = await analysis_service.generate_weekly_report("child_001")

        assert result["child_id"] == "child_001"
        assert "week_start" in result
        assert "week_end" in result
        assert "total_study_time" in result
        assert "daily_average" in result
        assert "trend" in result


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
