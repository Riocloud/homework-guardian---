"""
Unit Tests for GPU Detector Service
"""

import pytest
from services.gpu_detector import GPUDetector


class TestGPUDetector:
    """Test GPU detection functionality"""
    
    def test_check_gpu_returns_dict(self):
        """Test that check_gpu returns a dictionary"""
        result = GPUDetector.check_gpu()
        assert isinstance(result, dict)
        
    def test_check_gpu_has_required_keys(self):
        """Test that result has required keys"""
        result = GPUDetector.check_gpu()
        required_keys = ['available', 'cuda_available', 'name', 'device_count']
        for key in required_keys:
            assert key in result, f"Missing key: {key}"
            
    def test_get_device_returns_torch_device(self):
        """Test that get_device returns a torch.device"""
        device = GPUDetector.get_device()
        assert device is not None
        assert hasattr(device, 'type')
        
    def test_cuda_availability_reflects_in_device(self):
        """Test that device type matches CUDA availability"""
        gpu_info = GPUDetector.check_gpu()
        device = GPUDetector.get_device()
        
        if gpu_info['available']:
            assert 'cuda' in str(device)
        else:
            assert 'cpu' in str(device)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
