"""
GPU Detection and Management Service
Detects and manages NVIDIA GPU resources
"""

import torch
import platform
import logging
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)


class GPUDetector:
    """GPU detection and management utility"""
    
    @staticmethod
    def check_gpu() -> Dict[str, Any]:
        """
        Check GPU availability and properties
        
        Returns:
            dict: GPU information including availability, name, memory, etc.
        """
        result = {
            "available": False,
            "cuda_available": False,
            "name": None,
            "memory_total": None,
            "memory_free": None,
            "memory_used": None,
            "device_count": 0,
            "driver_version": None,
            "cuda_version": None,
            "platform": platform.system()
        }
        
        # Check CUDA availability
        if torch.cuda.is_available():
            result["cuda_available"] = True
            result["available"] = True
            result["device_count"] = torch.cuda.device_count()
            result["cuda_version"] = torch.version.cuda
            
            # Get GPU details
            if result["device_count"] > 0:
                gpu = torch.cuda.get_device_properties(0)
                result["name"] = gpu.name
                result["memory_total"] = round(gpu.total_memory / 1024**3, 2)  # GB
                result["memory_free"] = round(torch.cuda.mem_get_info()[0] / 1024**3, 2)
                result["memory_used"] = round(torch.cuda.mem_get_info()[1] / 1024**3, 2)
                result["driver_version"] = torch.cuda.get_device_capability(0)
                
                logger.info(f"GPU detected: {result['name']}")
                logger.info(f"Memory: {result['memory_free']}GB free / {result['memory_total']}GB total")
        else:
            logger.warning("No GPU detected - running on CPU")
            
        return result
    
    @staticmethod
    def get_device(device_id: int = 0) -> torch.device:
        """
        Get torch device
        
        Args:
            device_id: GPU device ID
            
        Returns:
            torch.device: CPU or CUDA device
        """
        if torch.cuda.is_available():
            return torch.device(f"cuda:{device_id}")
        return torch.device("cpu")
    
    @staticmethod
    def optimize_for_inference(model):
        """
        Optimize model for inference using TensorRT (if available)
        
        Args:
            model: PyTorch model
            
        Returns:
            Optimized model
        """
        if torch.cuda.is_available():
                   # Use torch.compile for optimization (PyTorch 2.0+)
            try:
                model = torch.compile(model, mode="reduce-overhead")
                logger.info("Model optimized with torch.compile")
            except Exception as e:
                logger.warning(f"torch.compile not available: {e}")
                
            # Move to GPU
            model = model.to(torch.cuda.current_device())
            logger.info("Model moved to GPU")
        else:
            logger.warning("No GPU available - running on CPU")
            
        return model
    
    @staticmethod
    def clear_cache():
        """Clear GPU cache"""
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
            logger.info("GPU cache cleared")


# Singleton instance
gpu_detector = GPUDetector()
