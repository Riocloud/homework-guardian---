"""
Simulation Script - Simulates full server behavior
Tests the complete workflow: Mobile -> Server -> Alert -> Email
"""

import asyncio
import random
from datetime import datetime, timedelta
from services.alert_service import AlertService
from services.analysis_service import AnalysisService
from services.email_service import EmailService
from services.gpu_detector import GPUDetector
from models.schemas import AlertConfig, ActivityType
from pydantic import EmailStr


class Simulation:
    """Simulates the HomeworkGuardian system"""
    
    def __init__(self):
        self.alert_service = AlertService()
        self.analysis_service = AnalysisService()
        self.email_service = EmailService()
        
    async def run(self):
        """Run complete simulation"""
        print("=" * 60)
        print("🏠 HomeworkGuardian System Simulation")
        print("=" * 60)
        
        # 1. Check GPU
        print("\n📊 Step 1: GPU Detection")
        gpu_info = GPUDetector.check_gpu()
        print(f"   GPU Available: {gpu_info['available']}")
        print(f"   GPU Name: {gpu_info.get('name', 'N/A')}")
        print(f"   Memory: {gpu_info.get('memory_total', 'N/A')} GB")
        
        # 2. Configure Alerts
        print("\n⚙️ Step 2: Alert Configuration")
        config = AlertConfig(
            child_id="xiaoming",
            email=EmailStr("parent@example.com"),
            leave_threshold_minutes=15,
            play_while_work_threshold_minutes=5,
            enable_email=False  # Disable for simulation
        )
        await self.alert_service.update_config(config)
        print(f"   ✅ Alert configured for: {config.child_id}")
        print(f"   📧 Leave threshold: {config.leave_threshold_minutes} min")
        print(f"   📧 Play-while-work threshold: {config.play_while_work_threshold_minutes} min")
        
        # 3. Start Monitoring Session
        print("\n🎬 Step 3: Start Monitoring Session")
        session_id = "session_20260221_001"
        await self.alert_service.start_session(session_id, config.child_id)
        print(f"   ✅ Session started: {session_id}")
        
        # 4. Simulate Activities
        print("\n📹 Step 4: Simulating Activities (30 min timeline)")
        
        activities = [
            ("studying", 300),   # 5 min studying
            ("idle", 60),        # 1 min idle
            ("studying", 600),   # 10 min studying
            ("away", 1800),      # 30 min AWAY (should trigger alert!)
            ("studying", 300),   # 5 min studying
            ("playing", 360),    # 6 min playing (should trigger alert!)
            ("studying", 300),   # 5 min studying
        ]
        
        total_study_time = 0
        for activity, duration in activities:
            print(f"   🔄 {activity} for {duration}s ({duration//60} min)")
            
            # Check for alerts
            alerts = await self.alert_service.check_and_trigger(
                session_id, config.child_id, activity, duration
            )
            
            if alerts:
                for alert in alerts:
                    print(f"      ⚠️  ALERT TRIGGERED: {alert}")
            
            # Track study time
            if activity == "studying":
                total_study_time += duration
        
        # 5. End Session
        print("\n🏁 Step 5: End Session")
        await self.alert_service.end_session(session_id)
        
        # 6. Generate Report
        print("\n📊 Step 6: Generate Report")
        report = await self.analysis_service.generate_daily_report(config.child_id)
        
        print(f"   📈 Total Study Time: {total_study_time}s ({total_study_time/60:.1f} min)")
        print(f"   📈 Focus Score: {report['focus_score']}%")
        
        # 7. Get Alert Status
        print("\n🔔 Step 7: Alert Summary")
        status = await self.alert_service.get_status(session_id)
        print(f"   Alerts Sent: {len(status.get('alerts_sent', []))}")
        
        print("\n" + "=" * 60)
        print("✅ Simulation Complete!")
        print("=" * 60)
        
        return {
            "session_id": session_id,
            "total_study_time": total_study_time,
            "alerts_triggered": status.get("alerts_sent", []),
            "focus_score": report["focus_score"]
        }


async def test_gpu_fallback():
    """Test GPU detection with fallback"""
    print("\n🧪 Testing GPU Fallback Mechanism")
    print("-" * 40)
    
    # Check GPU
    gpu_info = GPUDetector.check_gpu()
    
    if gpu_info['available']:
        print("✅ GPU detected - using CUDA acceleration")
        device = GPUDetector.get_device()
        print(f"   Device: {device}")
    else:
        print("⚠️  No GPU - falling back to CPU")
        device = GPUDetector.get_device()
        print(f"   Device: {device}")
        
    return gpu_info


async def main():
    """Main entry point"""
    # Test GPU
    await test_gpu_fallback()
    
    print("\n" + "=" * 60)
    
    # Run simulation
    sim = Simulation()
    result = await sim.run()
    
    return result


if __name__ == "__main__":
    result = asyncio.run(main())
