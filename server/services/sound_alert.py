"""
Sound Alert Service
Based on tonyliugd/monitoringStudy reference (uses pygame for audio)
"""

import os
import logging
from typing import Optional, List
from pathlib import Path

logger = logging.getLogger(__name__)

# Try to import pygame
try:
    import pygame
    PYGAME_AVAILABLE = True
except ImportError:
    PYGAME_AVAILABLE = False
    logger.warning("Pygame not available - sound alerts disabled")


class SoundAlert:
    """Sound alert system for monitoring"""
    
    # Alert types
    ALERT_LEAVE = "leave"
    ALERT_PLAY = "play"
    ALERT_SESSION_START = "session_start"
    ALERT_SESSION_END = "session_end"
    
    def __init__(self, sounds_dir: str = "/app/sounds"):
        self.sounds_dir = Path(sounds_dir)
        self.enabled = PYGAME_AVAILABLE
        
        if self.enabled:
            pygame.mixer.init()
            logger.info("Sound alert system initialized")
        else:
            logger.warning("Sound alerts disabled - install pygame")
        
        # Pre-load sounds
        self.sounds = {}
        self._load_sounds()
    
    def _load_sounds(self):
        """Load alert sounds"""
        if not self.enabled:
            return
        
        # Default sounds (in production, add actual sound files)
        sound_files = {
            self.ALERT_LEAVE: "alert_leave.wav",
            self.ALERT_PLAY: "alert_play.wav",
            self.ALERT_SESSION_START: "session_start.wav",
            self.ALERT_SESSION_END: "session_end.wav"
        }
        
        for alert_type, filename in sound_files.items():
            filepath = self.sounds_dir / filename
            if filepath.exists():
                try:
                    self.sounds[alert_type] = pygame.mixer.Sound(str(filepath))
                    logger.info(f"Loaded sound: {filename}")
                except Exception as e:
                    logger.warning(f"Could not load sound {filename}: {e}")
            else:
                logger.info(f"Sound file not found: {filepath} (will use system beep)")
    
    def play(self, alert_type: str, volume: float = 0.8):
        """
        Play alert sound
        
        Args:
            alert_type: Type of alert (ALERT_LEAVE, ALERT_PLAY, etc.)
            volume: Volume level 0.0-1.0
        """
        if not self.enabled:
            logger.warning(f"Sound alert ({alert_type}) - Pygame not available")
            return
        
        sound = self.sounds.get(alert_type)
        if sound:
            sound.set_volume(volume)
            sound.play()
            logger.info(f"Playing sound: {alert_type}")
        else:
            # Fallback to system beep
            self._system_beep(frequency=800, duration=0.3)
            logger.info(f"Playing fallback beep: {alert_type}")
    
    def _system_beep(self, frequency: int = 800, duration: float = 0.3):
        """System beep fallback"""
        try:
            # Try using os.system beep
            if os.name == 'posix':
                os.system(f'beep -f {frequency} -l {int(duration * 1000)}')
        except:
            pass
    
    def play_alert(self, alert_type: str):
        """Play alert with default settings"""
        self.play(alert_type, volume=0.8)
    
    def play_sequence(self, alert_types: List[str]):
        """Play a sequence of alerts"""
        for alert_type in alert_types:
            self.play(alert_type)
            # Small delay between alerts
            import time
            time.sleep(0.5)
    
    def stop(self):
        """Stop all sounds"""
        if self.enabled:
            pygame.mixer.stop()
    
    def set_volume(self, volume: float):
        """Set global volume"""
        if self.enabled:
            pygame.mixer.music.set_volume(volume)


class AlertManager:
    """
    Manages both sound and email alerts
    Combines tonyliugd reference (sound) with our design (email)
    """
    
    def __init__(self):
        self.sound_alert = SoundAlert()
        self.last_sound_alert_time = {}  # Track last alert time to avoid spam
    
    def trigger_alert(
        self,
        alert_type: str,
        enable_sound: bool = True,
        enable_email: bool = False,
        email_service = None,
        recipient: str = None
    ):
        """
        Trigger alert through configured channels
        
        Args:
            alert_type: Type of alert
            enable_sound: Play sound alert
            enable_email: Send email alert
            email_service: Email service instance
            recipient: Email recipient
        """
        import time
        
        # Rate limiting - don't spam alerts
        current_time = time.time()
        last_time = self.last_sound_alert_time.get(alert_type, 0)
        
        # Only alert once per minute per type
        if current_time - last_time < 60:
            logger.debug(f"Alert {alert_type} rate-limited")
            return
        
        self.last_sound_alert_time[alert_type] = current_time
        
        # Sound alert
        if enable_sound:
            self.sound_alert.play_alert(alert_type)
        
        # Email alert
        if enable_email and email_service and recipient:
            import asyncio
            try:
                asyncio.run(email_service.send_alert(
                    recipient,
                    alert_type,
                    "Child",
                    "Alert triggered"
                ))
            except Exception as e:
                logger.error(f"Email alert failed: {e}")


# Singleton
sound_alert = SoundAlert()
alert_manager = AlertManager()
