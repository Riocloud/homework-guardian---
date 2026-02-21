"""
MediaPipe Integration Service
Based on tonyliugd/monitoringStudy reference
"""

import cv2
import numpy as np
from typing import Dict, Any, Tuple, Optional
import logging

logger = logging.getLogger(__name__)

# Try to import MediaPipe
try:
    import mediapipe as mp
    MEDIAPIPE_AVAILABLE = True
except ImportError:
    MEDIAPIPE_AVAILABLE = False
    logger.warning("MediaPipe not available - using fallback detection")


class PoseDetector:
    """Pose and gesture detection using MediaPipe"""
    
    def __init__(self):
        self.mp_pose = None
        self.mp_hands = None
        self.pose = None
        self.hands = None
        
        if MEDIAPIPE_AVAILABLE:
            self.mp_pose = mp.solutions.pose
            self.mp_hands = mp.solutions.hands
            
            self.pose = self.mp_pose.Pose(
                static_image_mode=False,
                model_complexity=1,
                min_detection_confidence=0.5,
                min_tracking_confidence=0.5
            )
            self.hands = self.mp_hands.Hands(
                static_image_mode=False,
                max_num_hands=2,
                min_detection_confidence=0.5,
                min_tracking_confidence=0.5
            )
            
            logger.info("MediaPipe initialized successfully")
        else:
            logger.warning("Using fallback detection - install mediapipe for better results")
    
    def detect(self, frame: np.ndarray) -> Dict[str, Any]:
        """
        Detect person, pose, and hands in frame
        
        Returns:
            dict: Detection results including:
                - person_detected: bool
                - pose_landmarks: list or None
                - hands_detected: list
                - hand_positions: dict
        """
        if not MEDIAPIPE_AVAILABLE:
            return self._fallback_detect(frame)
        
        # Convert to RGB
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = {}
        
        # Detect pose
        pose_results = self.pose.process(rgb_frame)
        results["person_detected"] = pose_results.pose_landmarks is not None
        
        if pose_results.pose_landmarks:
            results["pose_landmarks"] = pose_results.pose_landmarks
        else:
            results["pose_landmarks"] = None
        
        # Detect hands
        hand_results = self.hands.process(rgb_frame)
        hands_list = []
        
        if hand_results.multi_hand_landmarks:
            for hand_landmarks in hand_results.multi_hand_landmarks:
                # Get key points
                wrist = hand_landmarks.landmark[0]
                index_tip = hand_landmarks.landmark[8]
                thumb_tip = hand_landmarks.landmark[4]
                
                hands_list.append({
                    "wrist": (wrist.x, wrist.y, wrist.z),
                    "index_tip": (index_tip.x, index_tip.y, index_tip.z),
                    "thumb_tip": (thumb_tip.x, thumb_tip.y, thumb_tip.z)
                })
        
        results["hands_detected"] = len(hands_list) > 0
        results["hands"] = hands_list
        
        return results
    
    def analyze_study_behavior(self, detection_results: Dict) -> Tuple[str, float]:
        """
        Analyze if the person is studying, playing, or away
        
        Args:
            detection_results: Results from detect()
            
        Returns:
            tuple: (activity_type, confidence)
        """
        if not detection_results.get("person_detected"):
            return "away", 0.9
        
        pose_landmarks = detection_results.get("pose_landmarks")
        hands = detection_results.get("hands", [])
        
        if not pose_landmarks:
            return "unknown", 0.5
        
        # Get key body points
        # Nose = 0, Shoulders = 11,12, Hips = 23,24
        
        # Calculate head tilt (indicator of looking down at desk)
        nose = pose_landmarks.landmark[0]
        left_shoulder = pose_landmarks.landmark[11]
        right_shoulder = pose_landmarks.landmark[12]
        
        # Head position relative to shoulders
        head_y = (left_shoulder.y + right_shoulder.y) / 2
        head_forward = nose.z  # Negative = forward
        
        # Check for hands near face (playing with phone)
        if hands:
            for hand in hands:
                # Check if hand is raised to face level
                wrist_y = hand["wrist"][1]
                wrist_x = hand["wrist"][0]
                
                # If wrist is above shoulders and near face center
                if wrist_y < head_y and abs(wrist_x - nose.x) < 0.2:
                    return "playing", 0.85
        
        # Check for proper study posture
        # Looking down (typical for reading/writing)
        if head_forward < -0.1:  # Leaning forward
            return "studying", 0.8
        
        # Idle - looking around or not at desk
        return "idle", 0.6
    
    def _fallback_detect(self, frame: np.ndarray) -> Dict[str, Any]:
        """Fallback detection using simple motion analysis"""
        # Simple fallback - detect significant motion changes
        # This is a placeholder - real implementation would use motion detection
        
        return {
            "person_detected": True,  # Assume person for now
            "pose_landmarks": None,
            "hands_detected": False,
            "hands": []
        }
    
    def release(self):
        """Release MediaPipe resources"""
        if self.pose:
            self.pose.close()
        if self.hands:
            self.hands.close()


class BehaviorAnalyzer:
    """Analyze study behavior over time"""
    
    def __init__(self):
        self.pose_detector = PoseDetector()
        self.activity_history = []
        self.max_history = 100  # Keep last 100 frames
        
    def analyze_frame(self, frame: np.ndarray) -> Dict[str, Any]:
        """Analyze a single frame"""
        # Detect
        detection = self.pose_detector.detect(frame)
        
        # Analyze behavior
        activity, confidence = self.pose_detector.analyze_study_behavior(detection)
        
        # Update history
        self.activity_history.append({
            "activity": activity,
            "confidence": confidence
        })
        
        if len(self.activity_history) > self.max_history:
            self.activity_history.pop(0)
        
        return {
            "detection": detection,
            "activity": activity,
            "confidence": confidence,
            "history": self.activity_history
        }
    
    def get_current_status(self) -> Dict[str, Any]:
        """Get current study status based on history"""
        if not self.activity_history:
            return {"status": "unknown", "confidence": 0}
        
        # Get recent activities (last 30 frames = ~1 second)
        recent = self.activity_history[-30:]
        
        # Count activities
        activities = [a["activity"] for a in recent]
        study_count = activities.count("studying")
        play_count = activities.count("playing")
        away_count = activities.count("away")
        idle_count = activities.count("idle")
        
        total = len(activities)
        
        # Determine status
        if away_count > total * 0.7:
            status = "away"
        elif play_count > total * 0.3:
            status = "playing"
        elif study_count > total * 0.5:
            status = "studying"
        else:
            status = "idle"
        
        return {
            "status": status,
            "study_ratio": study_count / total,
            "play_ratio": play_count / total,
            "away_ratio": away_count / total,
            "confidence": max([a["confidence"] for a in recent[-10:]]) if recent else 0
        }


# Singleton
pose_detector = PoseDetector()
behavior_analyzer = BehaviorAnalyzer()
