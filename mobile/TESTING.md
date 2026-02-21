# HomeworkGuardian Mobile - 测试指南

## 前置要求

### 1. 安装 Flutter SDK
```bash
# macOS / Linux
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 验证安装
flutter --version
```

### 2. 安装依赖
```bash
cd mobile
flutter pub get
```

## 运行测试

### 模拟器测试 (无需真机)
```bash
# 启动 iOS 模拟器
open -a Simulator

# 运行 iOS
flutter run -d "iPhone 15 Pro"

# 或者运行 Android 模拟器
flutter run -d android
```

### 真机测试
```bash
# iOS (需要 Mac)
flutter run -d <device_id>

# Android
flutter run -d <device_id>
```

## 项目结构

```
mobile/
├── lib/
│   ├── main.dart              # 主界面
│   ├── models/
│   │   └── models.dart        # 数据模型
│   └── services/
│       ├── ai_detection.dart  # AI 接口
│       ├── ios_ai_detection.dart   # iOS CoreML
│       ├── android_ai_detection.dart # Android TFLite
│       ├── video_service.dart   # 视频压缩
│       ├── api_client.dart      # API 客户端
│       └── session_manager.dart # 会话管理
├── android/                    # Android 配置
├── ios/                       # iOS 配置
└── test/                     # 测试文件
```

## 测试用例

### 1. AI 检测测试
```dart
// 测试 CoreML/TFLite 初始化
void testAIInitialization() async {
  final aiService = IOSAIDetectionService();
  await aiService.initialize();
  assert(aiService.isReady == true);
}
```

### 2. API 通信测试
```dart
// 测试服务器连接
void testApiConnection() async {
  final client = ApiClient(baseUrl: 'http://localhost:8000');
  final response = await client.testEmail('test@example.com');
  assert(response.success == true);
}
```

## 快速启动命令

```bash
# 完整构建
flutter build apk --debug        # Android Debug
flutter build ipa --debug       # iOS Debug (需要 Mac)

# 热重载开发
flutter run --hot
```
