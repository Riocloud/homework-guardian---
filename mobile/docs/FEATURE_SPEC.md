# 📋 Feature Specification - Mobile App Enhancements

## 1. Push Notifications

### 功能需求
- 本地推送通知 (离开/玩耍检测)
- 服务器端远程推送 (可选)
- 通知点击跳转对应页面

### 技术方案
- **iOS**: APNs (Apple Push Notification service)
- **Android**: FCM (Firebase Cloud Messaging)
- **本地**: flutter_local_notifications

---

## 2. Database Storage

### 功能需求
- 本地存储活动记录
- 缓存上传失败的数据
- 离线访问历史数据

### 技术方案
- **SQLite**: sqflite package
- **表结构**:
  - activities: 活动记录
  - sessions: 监控会话
  - videos: 视频片段
  - settings: 配置

---

## 3. Video Upload (Improved)

### 功能需求
- 后台上传
- 断点续传
- 上传进度显示
- 压缩优化

### 技术方案
- **dio**: HTTP 客户端
- **flutter_background_service**: 后台任务
- **ffmpeg_kit_flutter**: 视频压缩

---

## Implementation Plan

1. [x] Spec 定义
2. [ ] Database Service
3. [ ] Notification Service
4. [ ] Upload Service (Enhanced)
5. [ ] UI Integration
