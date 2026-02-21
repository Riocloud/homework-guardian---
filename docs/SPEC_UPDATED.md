# 📋 HomeworkGuardian - Updated SPEC

## 1. 系统架构 (更新)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Android/iOS   │────▶│   Cloud Server  │────▶│   Email Alert  │
│  (Edge Device)  │     │   (AI Engine)   │     │   (Parents)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │
        │ ◀─ 本地AI标记 ──────▶│
        │ ◀─ 关键片段上传 ─────▶│
        │                       │
   摄像头采集              数据存储
   本地AI推理              深度分析
   智能标记                模型推理

┌─────────────────────────────────────────────────┐
│        本地桌面端 (家长监控) - 可选组件          │
│  - Tkinter GUI                                  │
│  - 实时视频查看                                  │
│  - 声音提醒                                      │
└─────────────────────────────────────────────────┘
```

## 2. 功能对比参考表

| 功能 | 参考项目 | 本项目 | 优先级 |
|---|---|---|---|
| 实时视频监控 | ✅ | ✅ | P0 |
| 人体姿态检测 (MediaPipe) | ✅ | ✅ | P0 |
| 学习状态识别 | ✅ | ✅ | P0 |
| 离开检测提醒 | ✅ (5分钟) | ✅ (可配置) | P0 |
| 边学边玩检测 | ✅ | ✅ | P0 |
| 邮件推送 | ❌ | ✅ | P1 |
| 手机边缘计算 | ❌ | ✅ | P1 |
| 视频上传压缩 | ❌ | ✅ | P1 |
| 桌面 GUI | ✅ | 可选 | P2 |
| 声音提醒 | ✅ | 可选 | P2 |

## 3. 核心技术栈

### 手机端 / 边缘设备
- **Flutter**: 跨平台 UI
- **TensorFlow Lite**: 本地推理
- **MediaPipe**: 姿态/手势检测

### 服务器端
- **FastAPI**: API 服务
- **PyTorch + CUDA**: GPU 加速
- **MediaPipe**: 服务端姿态检测
- **PostgreSQL**: 数据存储

### 本地桌面端 (可选)
- **Python + Tkinter**: 桌面 GUI
- **OpenCV**: 视频处理
- **Pygame**: 声音提醒

## 4. 检测算法参考

参考项目的核心检测逻辑：

```python
# 1. 人体检测
if person_detected:
    # 2. 手部/姿态检测
    if hand_detected:
        # 检测是否在玩手机
        if hand_near_face:
            status = "playing"
        else:
            status = "studying"
    else:
        # 3. 离开检测
        status = "away"
else:
    status = "away"

# 4. 状态持续时间
if status != "studying":
    idle_duration += frame_time
    if idle_duration > threshold:
        trigger_alert()
```

## 5. 提醒规则 (可配置)

| 场景 | 参考项目默认值 | 本项目默认值 |
|---|---|---|
| 离开提醒 | 5 分钟 | 15 分钟 (可配置) |
| 边玩边学 | - | 5 分钟 (可配置) |
| 声音提醒 | ✅ | 可选 |

---

## 6. 待实现功能清单

- [ ] 桌面端 GUI (Tkinter)
- [ ] 声音提醒模块 (Pygame)
- [ ] MediaPipe 集成
- [ ] 多摄像头管理
- [ ] 本地推理优化 (TFLite)

---

*Last Updated: 2026-02-21*
