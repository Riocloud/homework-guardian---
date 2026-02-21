# 📋 Implementation Plan - HomeworkGuardian

## Overview
边缘计算 + 云端深度学习的孩子作业监控系统

---

## Phase 1: Server (Backend) - GPU Accelerated

### 1.1 技术栈
- **Framework**: FastAPI (Python 3.12+)
- **GPU加速**: CUDA 12.x + TensorRT + PyTorch
- **AI模型**: 
  - MediaPipe (姿态检测)
  - DeepSort (追踪)
  - 自研行为分类器
- **数据库**: PostgreSQL + Redis
- **邮件**: SMTP / Apline

### 1.2 核心模块

| 模块 | 功能 | 优先级 |
|---|---|---|
| `api/v1/upload` | 接收手机端数据 | P0 |
| `api/v1/analysis` | 深度分析接口 | P0 |
| `services/gpu_detector.py` | GPU加速推理 | P0 |
| `services/email_service.py` | 邮件推送 | P1 |
| `services/behavior_analyzer.py` | 行为分析 | P1 |

---

## Phase 2: Mobile App (Flutter)

### 2.1 技术栈
- **Framework**: Flutter 3.x
- **本地AI**: TensorFlow Lite / MediaPipe
- **视频处理**: FFmpeg (压缩/关键帧)
- **设计**: Material Design 3

### 2.2 核心功能

| 功能 | 描述 | 优先级 |
|---|---|---|
| 摄像头采集 | 实时视频流 | P0 |
| 本地状态检测 | 检测学习/离开/玩手机 | P0 |
| 智能标记 | 自动打标签 | P0 |
| 数据压缩 | 关键帧提取 | P1 |
| 边缘上传 | 选择性上传 | P1 |

---

## Phase 3: Deployment

### 3.1 本地部署 (NVIDIA GPU)
```bash
# 要求
- NVIDIA 5070ti+ 
- CUDA 12.x
- Docker + Docker Compose
- 32GB+ RAM
```

### 3.2 Docker Compose
- `server`: FastAPI + GPU
- `postgres`: 数据库
- `redis`: 缓存
- `nginx`: 反向代理

---

## Task Breakdown (TDD + YAGNI)

### Sprint 1: Server 核心
- [ ] FastAPI 项目初始化
- [ ] GPU 检测模块
- [ ] 基础 API (上传/查询)
- [ ] Docker 配置

### Sprint 2: AI 推理
- [ ] MediaPipe 集成
- [ ] 行为分类模型
- [ ] CUDA 加速

### Sprint 3: Mobile App
- [ ] Flutter 项目
- [ ] 摄像头模块
- [ ] 本地推理

### Sprint 4: 通知系统
- [ ] 邮件服务
- [ ] 提醒逻辑
- [ ] 报告生成

---

## Next Step
开始写 Server 端代码 (Phase 1)
