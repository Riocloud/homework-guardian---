"""
HomeworkGuardian Server - Main Application
GPU-accelerated backend for child's homework monitoring
"""

import torch
import cv2
from contextlib import asynccontextmanager
from fastapi import FastAPI, UploadFile, File, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, timedelta
import logging

from api import routes
from core.config import settings
from core.database import init_db, close_db
from services.gpu_detector import GPUDetector
from services.email_service import EmailService

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler"""
    # Startup
    logger.info("Starting HomeworkGuardian Server...")
    
    # Initialize database
    await init_db()
    
    # Check GPU availability
    gpu_info = GPUDetector.check_gpu()
    logger.info(f"GPU Status: {gpu_info}")
    
    if gpu_info["available"]:
        logger.info(f"Using GPU: {gpu_info['name']}")
    else:
        logger.warning("Running on CPU - performance will be limited")
    
    yield
    
    # Shutdown
    logger.info("Shutting down HomeworkGuardian Server...")
    await close_db()


# Create FastAPI app
app = FastAPI(
    title="HomeworkGuardian API",
    description="GPU-accelerated homework monitoring system",
    version="1.0.0",
    docs="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(routes.router, prefix="/api/v1", tags=["api"])


# Root endpoint
@app.get("/")
async def root():
    return {
        "message": "HomeworkGuardian API",
        "version": "1.0.0",
        "status": "running"
    }


# Health check
@app.get("/health")
async def health_check():
    gpu_info = GPUDetector.check_gpu()
    return {
        "status": "healthy",
        "gpu": gpu_info,
        "timestamp": datetime.utcnow().isoformat()
    }


# GPU info endpoint
@app.get("/api/v1/gpu/status")
async def gpu_status():
    """Get current GPU status"""
    return GPUDetector.check_gpu()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        workers=1
    )
