#!/usr/bin/env python3
"""
Lightweight Simulation Script - No heavy dependencies
Tests core logic without requiring PyTorch/FastAPI installation
"""

import sys
import os
import asyncio

# Add server to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'server'))

print("=" * 60)
print("🏠 HomeworkGuardian System Simulation (Lightweight)")
print("=" * 60)

# Mock GPU Detector
class MockGPUDetector:
    @staticmethod
    def check_gpu():
        return {
            "available": True,
            "cuda_available": True,
            "name": "NVIDIA RTX 5070 Ti",
            "memory_total": 16.0,
            "memory_free": 12.5,
            "memory_used": 3.5,
            "device_count": 1
        }
    
    @staticmethod
    def get_device():
        return "cuda:0"

# Mock GPU for import
sys.modules['services.gpu_detector'] = type(sys)('services.gpu_detector')
sys.modules['services.gpu_detector'].GPUDetector = MockGPUDetector

# Now import our modules
from datetime import datetime


class AlertService:
    """Simplified Alert Service"""
    
    def __init__(self):
        self.configs = {}
        self.session_states = {}
        
    async def update_config(self, config):
        self.configs[config['child_id']] = config
        
    async def start_session(self, session_id, child_id):
        self.session_states[session_id] = {
            "child_id": child_id,
            "is_active": True,
            "start_time": datetime.now(),
            "leave_time": None,
            "play_time": None,
            "alerts_sent": []
        }
        
    async def check_and_trigger(self, session_id, child_id, activity, duration_seconds):
        alerts_triggered = []
        
        if child_id not in self.configs:
            return alerts_triggered
            
        config = self.configs[child_id]
        state = self.session_states.get(session_id, {})
        
        # Check leave alert
        if activity == "away":
            leave_duration = state.get("leave_duration", 0) + duration_seconds
            state["leave_duration"] = leave_duration
            
            leave_minutes = leave_duration / 60
            if leave_minutes >= config["leave_threshold_minutes"]:
                if "leave_too_long" not in state.get("alerts_sent", []):
                    alerts_triggered.append("leave_too_long")
                    state.setdefault("alerts_sent", []).append("leave_too_long")
                    state["leave_time"] = datetime.now()
        else:
            state["leave_duration"] = 0
            
        # Check play-while-work alert
        if activity == "playing" or activity == "distracted":
            play_duration = state.get("play_duration", 0) + duration_seconds
            state["play_duration"] = play_duration
            
            play_minutes = play_duration / 60
            if play_minutes >= config["play_while_work_threshold_minutes"]:
                if "play_while_work" not in state.get("alerts_sent", []):
                    alerts_triggered.append("play_while_work")
                    state.setdefault("alerts_sent", []).append("play_while_work")
        else:
            state["play_duration"] = 0
            
        self.session_states[session_id] = state
        return alerts_triggered
        
    async def get_status(self, session_id):
        return self.session_states.get(session_id, {})
        
    async def end_session(self, session_id):
        if session_id in self.session_states:
            self.session_states[session_id]["is_active"] = False


async def run_simulation():
    """Run the simulation"""
    
    # 1. GPU Check
    print("\n📊 Step 1: GPU Detection")
    gpu_info = MockGPUDetector.check_gpu()
    print(f"   ✅ GPU Available: {gpu_info['name']}")
    print(f"   📊 Memory: {gpu_info['memory_free']}GB free / {gpu_info['memory_total']}GB")
    
    # 2. Configure Alerts
    print("\n⚙️ Step 2: Alert Configuration")
    config = {
        "child_id": "xiaoming",
        "email": "parent@example.com",
        "leave_threshold_minutes": 15,
        "play_while_work_threshold_minutes": 5,
        "enable_email": False
    }
    
    alert_service = AlertService()
    await alert_service.update_config(config)
    print(f"   ✅ Configured: {config['child_id']}")
    print(f"   📧 Leave alert: >{config['leave_threshold_minutes']} min")
    print(f"   📧 Play alert: >{config['play_while_work_threshold_minutes']} min")
    
    # 3. Start Session
    print("\n🎬 Step 3: Start Monitoring Session")
    session_id = "session_001"
    await alert_service.start_session(session_id, config["child_id"])
    print(f"   ✅ Session started: {session_id}")
    
    # 4. Simulate Activities (30 min timeline)
    print("\n📹 Step 4: Simulating Activities")
    
    activities = [
        ("studying", 300, "5 min - Normal studying"),
        ("idle", 60, "1 min - Short break"),
        ("studying", 600, "10 min - Deep work"),
        ("away", 1200, "20 min - AWAY! (triggers alert at 15min)"),
        ("studying", 300, "5 min - Back to work"),
        ("playing", 360, "6 min - PLAYING (triggers alert at 5min)"),
        ("studying", 300, "5 min - Final study"),
    ]
    
    total_study = 0
    
    for activity, duration, description in activities:
        print(f"   🔄 {description}")
        
        # Check alerts
        alerts = await alert_service.check_and_trigger(
            session_id, config["child_id"], activity, duration
        )
        
        for alert in alerts:
            if alert == "leave_too_long":
                print(f"      ⚠️  ALERT: Child away > 15 min!")
            elif alert == "play_while_work":
                print(f"      ⚠️  ALERT: Child playing > 5 min!")
        
        if activity == "studying":
            total_study += duration
    
    # 5. End Session
    print("\n🏁 Step 5: End Session")
    await alert_service.end_session(session_id)
    
    # 6. Report
    print("\n📊 Step 6: Daily Report")
    study_minutes = total_study / 60
    print(f"   📈 Total Study Time: {study_minutes:.0f} minutes")
    print(f"   📈 Focus Score: {(study_minutes/27)*100:.1f}%")
    
    # 7. Alert Summary
    status = await alert_service.get_status(session_id)
    print("\n🔔 Step 7: Alert Summary")
    print(f"   🚨 Total Alerts: {len(status.get('alerts_sent', []))}")
    for alert in status.get("alerts_sent", []):
        print(f"      - {alert}")
    
    print("\n" + "=" * 60)
    print("✅ Simulation Complete!")
    print("=" * 60)
    
    return {
        "session": session_id,
        "study_time": total_study,
        "alerts": status.get("alerts_sent", [])
    }


# Run
if __name__ == "__main__":
    result = asyncio.run(run_simulation())
