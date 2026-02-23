import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'models/models.dart';
import 'screens/splash_screen.dart';
import 'services/settings_service.dart';

void main() {
  runApp(const HomeworkGuardianApp());
}

/// 主应用入口
class HomeworkGuardianApp extends StatelessWidget {
  const HomeworkGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..initialize()),
        ChangeNotifierProvider(create: (_) => SettingsService()..load()),
      ],
      child: MaterialApp(
        title: 'HomeworkGuardian',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/': (_) => const HomeScreen(),
        },
      ),
    );
  }
}

/// 主页 - 监控和控制
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, SettingsService>(
      builder: (context, state, settings, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 10),
                const Text('HomeworkGuardian', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              IconButton(
                icon: Badge(
                  label: Text('${state.pendingCount}'),
                  isLabelVisible: state.pendingCount > 0 && !state.isSyncing,
                  child: const Icon(Icons.sync_rounded),
                ),
                onPressed: state.isSyncing ? null : () => state.syncData(),
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 同步进度条
                  if (state.isSyncing) _SyncProgressBar(state: state),
                  
                  // 状态卡片
                  _StatusCard(state: state, childName: settings.childName),
                  const SizedBox(height: 16),
                  
                  // 快速统计
                  _QuickStats(state: state),
                  const SizedBox(height: 16),
                  
                  // 今日活动
                  _ActivitySection(state: state),
                  const SizedBox(height: 16),
                  
                  // 数据统计
                  _DataStats(state: state),
                  const SizedBox(height: 16),
                  
                  // 操作按钮
                  _ControlButtons(state: state, childId: settings.childId),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _BottomNav(state: state),
        );
      },
    );
  }
}

/// 同步进度条
class _SyncProgressBar extends StatelessWidget {
  final AppState state;
  const _SyncProgressBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(state.syncStatus),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: state.syncProgress),
          ],
        ),
      ),
    );
  }
}

/// 状态卡片
class _StatusCard extends StatelessWidget {
  final AppState state;
  final String childName;
  const _StatusCard({required this.state, required this.childName});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: state.isMonitoring
          ? AppTheme.primaryColor.withOpacity(0.08)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isMonitoring ? AppTheme.successColor : Colors.grey.shade400,
                    boxShadow: state.isMonitoring
                        ? [BoxShadow(color: AppTheme.successColor.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)]
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  state.isMonitoring ? '正在监控 $childName' : '未在监控',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (state.isMonitoring) ...[
              Text(
                state.currentStatus,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getStatusColor(state.currentStatus),
                ),
              ),
            ] else
              Text(
                '点击下方按钮开始监控',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 快速统计
class _QuickStats extends StatelessWidget {
  final AppState state;
  const _QuickStats({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.timer,
          label: '学习时长',
          value: '${state.studyMinutes} 分钟',
          color: AppTheme.infoColor,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          icon: Icons.psychology,
          label: '专注度',
          value: '${state.focusScore}%',
          color: AppTheme.successColor,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          icon: Icons.warning,
          label: '警告',
          value: '0 次',
          color: AppTheme.warningColor,
        )),
      ],
    );
  }
}

/// 统计卡片
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatCard({
    required this.icon, 
    required this.label, 
    required this.value, 
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// 活动列表
class _ActivitySection extends StatelessWidget {
  final AppState state;
  const _ActivitySection({required this.state});

  @override
  Widget build(BuildContext context) {
    // 模拟数据
    final activities = [
      _ActivityItem('学习中', '10:30', '11:00', AppTheme.studyingColor),
      _ActivityItem('离开', '11:00', '11:18', AppTheme.awayColor),
      _ActivityItem('学习中', '11:18', '12:00', AppTheme.studyingColor),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('今日活动', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(onPressed: () {}, child: const Text('查看全部')),
              ],
            ),
            const Divider(),
            ...activities.map((a) => _ActivityTile(activity: a)),
          ],
        ),
      ),
    );
  }
}

/// 活动项
class _ActivityTile extends StatelessWidget {
  final _ActivityItem activity;
  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: activity.color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.status, style: Theme.of(context).textTheme.bodyLarge),
                Text('${activity.startTime} - ${activity.endTime}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(activity.duration, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String status;
  final String startTime;
  final String endTime;
  final Color color;
  _ActivityItem(this.status, this.startTime, this.endTime, this.color);
  String get duration {
    final start = DateTime.parse('2024-01-01 $startTime:00');
    final end = DateTime.parse('2024-01-01 $endTime:00');
    return '${end.difference(start).inMinutes} 分钟';
  }
}

/// 数据统计
class _DataStats extends StatelessWidget {
  final AppState state;
  const _DataStats({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('数据统计', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _DataItem(icon: Icons.storage, label: '本地记录', value: '156 条', color: AppTheme.infoColor)),
                Expanded(child: _DataItem(icon: Icons.cloud_upload, label: '待上传', value: '${state.pendingCount} 条', color: state.pendingCount > 0 ? AppTheme.warningColor : AppTheme.successColor)),
                Expanded(child: _DataItem(icon: Icons.check_circle, label: '已同步', value: '128 条', color: AppTheme.successColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DataItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DataItem({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// 控制按钮
class _ControlButtons extends StatelessWidget {
  final AppState state;
  final String childId;
  const _ControlButtons({required this.state, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraSetupScreen())),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('摄像头'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: state.isMonitoring ? () => state.stopMonitoring() : () => state.startMonitoring(childId: childId),
            icon: Icon(state.isMonitoring ? Icons.stop : Icons.play_arrow),
            label: Text(state.isMonitoring ? '停止监控' : '开始监控'),
            style: FilledButton.styleFrom(
              backgroundColor: state.isMonitoring ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// 底部导航
class _BottomNav extends StatelessWidget {
  final AppState state;
  const _BottomNav({required this.state});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
        if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '监控'),
        NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: '报告'),
        NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: '历史'),
      ],
    );
  }
}

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Consumer<SettingsService>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _Section(title: '孩子信息', children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                  ),
                  title: const Text('孩子姓名'),
                  subtitle: Text(settings.childName),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showChildNameDialog(context, settings),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.face_rounded, color: AppTheme.infoColor),
                  ),
                  title: const Text('人脸录入'),
                  subtitle: const Text('已录入 1 张'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ]),
              _Section(title: '提醒设置', children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_rounded),
                  title: const Text('推送通知'),
                  subtitle: const Text('检测到异常时推送'),
                  value: settings.pushNotifications,
                  onChanged: (v) => settings.setPushNotifications(v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.email_rounded),
                  title: const Text('邮件提醒'),
                  subtitle: Text(settings.emailAddress.isEmpty ? '未设置' : settings.emailAddress),
                  value: settings.emailAlerts,
                  onChanged: (v) => settings.setEmailAlerts(v),
                ),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('离开提醒阈值'),
                  subtitle: Text('${settings.leaveThresholdMinutes} 分钟'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showLeaveThresholdSheet(context, settings),
                ),
                ListTile(
                  leading: const Icon(Icons.sports_esports_outlined),
                  title: const Text('玩耍提醒阈值'),
                  subtitle: Text('${settings.playThresholdMinutes} 分钟'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showPlayThresholdSheet(context, settings),
                ),
              ]),
              _Section(title: '数据同步', children: [
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('服务器地址'),
                  subtitle: Text(settings.serverUrl, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showServerUrlDialog(context, settings),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.sync_rounded),
                  title: const Text('自动同步'),
                  subtitle: Text('每 ${settings.syncIntervalMinutes} 分钟'),
                  value: settings.autoSync,
                  onChanged: (v) => settings.setAutoSync(v),
                ),
              ]),
              _Section(title: 'AI 性能', children: [
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('检测间隔'),
                  subtitle: Text('${settings.aiFrameIntervalMs} ms'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showAiIntervalSheet(context, settings),
                ),
                ListTile(
                  leading: const Icon(Icons.memory_outlined),
                  title: const Text('推理线程数'),
                  subtitle: Text('${settings.aiInferenceThreads}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showAiThreadsSheet(context, settings),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.battery_saver_rounded),
                  title: const Text('低功耗模式'),
                  subtitle: const Text('降低检测频率，节省电量'),
                  value: settings.aiLowPowerMode,
                  onChanged: (v) => settings.setAiLowPowerMode(v),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  static void _showChildNameDialog(BuildContext context, SettingsService settings) {
    final c = TextEditingController(text: settings.childName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('孩子姓名'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: '输入姓名'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) settings.setChildName(c.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  static void _showLeaveThresholdSheet(BuildContext context, SettingsService settings) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ThresholdPicker(
        title: '离开提醒阈值',
        value: settings.leaveThresholdMinutes,
        min: 5,
        max: 60,
        step: 5,
        unit: '分钟',
        onChanged: (v) => settings.setLeaveThresholdMinutes(v),
      ),
    );
  }

  static void _showPlayThresholdSheet(BuildContext context, SettingsService settings) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ThresholdPicker(
        title: '玩耍提醒阈值',
        value: settings.playThresholdMinutes,
        min: 1,
        max: 30,
        step: 1,
        unit: '分钟',
        onChanged: (v) => settings.setPlayThresholdMinutes(v),
      ),
    );
  }

  static void _showServerUrlDialog(BuildContext context, SettingsService settings) {
    final c = TextEditingController(text: settings.serverUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('服务器地址'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'http://192.168.1.100:8000'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) settings.setServerUrl(c.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  static void _showAiIntervalSheet(BuildContext context, SettingsService settings) {
    const options = [250, 500, 750, 1000, 1500, 2000];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _OptionPicker(
        title: '检测间隔',
        options: options,
        value: settings.aiFrameIntervalMs,
        format: (v) => '$v ms',
        onChanged: (v) => settings.setAiFrameIntervalMs(v),
      ),
    );
  }

  static void _showAiThreadsSheet(BuildContext context, SettingsService settings) {
    const options = [1, 2, 4, 6];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _OptionPicker(
        title: '推理线程数',
        options: options,
        value: settings.aiInferenceThreads,
        format: (v) => '$v',
        onChanged: (v) => settings.setAiInferenceThreads(v),
      ),
    );
  }
}

class _ThresholdPicker extends StatefulWidget {
  final String title;
  final int value;
  final int min;
  final int max;
  final int step;
  final String unit;
  final ValueChanged<int> onChanged;

  const _ThresholdPicker({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<_ThresholdPicker> createState() => _ThresholdPickerState();
}

class _ThresholdPickerState extends State<_ThresholdPicker> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final options = <int>[];
    for (var i = widget.min; i <= widget.max; i += widget.step) {
      options.add(i);
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((v) {
              final selected = _value == v;
              return ChoiceChip(
                label: Text('$v ${widget.unit}'),
                selected: selected,
                onSelected: (_) {
                  setState(() => _value = v);
                  widget.onChanged(v);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _OptionPicker<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T value;
  final String Function(T) format;
  final ValueChanged<T> onChanged;

  const _OptionPicker({
    required this.title,
    required this.options,
    required this.value,
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((v) {
              final selected = value == v;
              return ChoiceChip(
                label: Text(format(v)),
                selected: selected,
                onSelected: (_) {
                  onChanged(v);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600))),
        ...children,
        const Divider(),
      ],
    );
  }
}

/// 摄像头设置
class CameraSetupScreen extends StatelessWidget {
  const CameraSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('摄像头设置')),
      body: ListView(
        children: [
          Container(height: 250, margin: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)), child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.videocam_off, color: Colors.white54, size: 48), SizedBox(height: 8), Text('摄像头未开启', style: TextStyle(color: Colors.white54))]))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('选择摄像头', style: Theme.of(context).textTheme.titleMedium)),
          ListTile(leading: const Icon(Icons.camera_front), title: const Text('前置摄像头'), subtitle: const Text('推荐用于监控'), trailing: const Icon(Icons.check_circle, color: Colors.green), onTap: () {}),
          ListTile(leading: const Icon(Icons.camera_rear), title: const Text('后置摄像头'), onTap: () {}),
          const Divider(),
          Padding(padding: const EdgeInsets.all(16), child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.play_arrow), label: const Text('预览摄像头'))),
        ],
      ),
    );
  }
}

/// 报告页面
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习报告')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('今日概览', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_Stat('2.5h', '学习时长', Colors.blue), _Stat('85%', '专注度', Colors.green), _Stat('3次', '离开', Colors.orange)])]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('本周趋势', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16), SizedBox(height: 150, child: _WeekChart())]))),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _Stat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)), Text(label, style: Theme.of(context).textTheme.bodySmall)]);
}

class _WeekChart extends StatelessWidget {
  final data = [0.6, 0.8, 0.5, 0.9, 0.7, 0.4, 0.3];
  final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(7, (i) => Column(mainAxisAlignment: MainAxisAlignment.end, children: [Container(width: 28, height: 100 * data[i], decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(4))), const SizedBox(height: 8), Text(days[i], style: const TextStyle(fontSize: 10))])));
}

/// 历史页面
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('历史记录')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.history),
          title: Text('2024-02-${20 - index}'),
          subtitle: Text('学习 ${2 + index * 0.5} 小时 • 专注度 ${70 + index}%'),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
