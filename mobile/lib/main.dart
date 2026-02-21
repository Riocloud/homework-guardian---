import 'package:flutter/material.dart';

void main() {
  runApp(const HomeworkGuardianApp());
}

/// 主应用入口
class HomeworkGuardianApp extends StatelessWidget {
  const HomeworkGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeworkGuardian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardTheme(
          elevation: 0,
          margin: EdgeInsets.symmetric(vertical: 4),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

/// 主页 - 监控和控制
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMonitoring = false;
  String _currentStatus = '等待开始';
  String _childName = '小明';
  int _studyMinutes = 0;
  int _focusScore = 0;
  DateTime? _sessionStartTime;
  
  // 同步状态
  bool _isSyncing = false;
  double _syncProgress = 0;
  String _syncStatus = '';
  int _pendingCount = 0;

  // 模拟数据
  final List<_ActivityItem> _activities = [
    _ActivityItem('学习中', '10:30', '11:00', Colors.green),
    _ActivityItem('离开', '11:00', '11:18', Colors.orange),
    _ActivityItem('学习中', '11:18', '12:00', Colors.green),
  ];

  void _startMonitoring() {
    setState(() {
      _isMonitoring = true;
      _currentStatus = '学习中';
      _sessionStartTime = DateTime.now();
      _studyMinutes = 0;
      _focusScore = 0;
    });

    // 模拟实时更新
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isMonitoring) {
        setState(() {
          _studyMinutes = 5;
          _focusScore = 88;
        });
      }
    });
  }

  void _stopMonitoring() {
    setState(() {
      _isMonitoring = false;
      _currentStatus = '已停止';
    });
  }

  void _startSync() async {
    setState(() {
      _isSyncing = true;
      _syncProgress = 0.1;
      _syncStatus = '正在同步...';
    });

    // 模拟同步过程
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _syncProgress = i * 0.1;
          _syncStatus = '正在上传 ($i/10)...';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _syncProgress = 1.0;
        _syncStatus = '同步完成 ✓';
        _pendingCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeworkGuardian'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Badge(
              label: Text('$_pendingCount'),
              isLabelVisible: _pendingCount > 0 && !_isSyncing,
              child: const Icon(Icons.sync),
            ),
            onPressed: _isSyncing ? null : _startSync,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
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
              if (_isSyncing) _buildSyncProgress(),
              
              // 状态卡片
              _buildStatusCard(),
              const SizedBox(height: 16),
              
              // 快速统计
              _buildQuickStats(),
              const SizedBox(height: 16),
              
              // 实时活动
              _buildActivitySection(),
              const SizedBox(height: 16),
              
              // 数据统计
              _buildDataStats(),
              const SizedBox(height: 16),
              
              // 操作按钮
              _buildControlButtons(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSyncProgress() {
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
                Text(_syncStatus),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _syncProgress),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _isMonitoring 
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isMonitoring ? Colors.green : Colors.grey,
                    boxShadow: _isMonitoring
                        ? [const BoxShadow(color: Colors.green, blurRadius: 8)]
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isMonitoring ? '正在监控 $_childName' : '未在监控',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isMonitoring) ...[
              Text(
                _currentStatus,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(_currentStatus),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _sessionStartTime != null 
                    ? '开始于 ${_formatTime(_sessionStartTime!)}'
                    : '',
                style: Theme.of(context).textTheme.bodySmall,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case '学习中':
        return Colors.green;
      case '离开':
        return Colors.orange;
      case '玩耍中':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          icon: Icons.timer,
          label: '学习时长',
          value: '$_studyMinutes 分钟',
          color: Colors.blue,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.psychology,
          label: '专注度',
          value: '$_focusScore%',
          color: Colors.green,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.warning,
          label: '警告',
          value: '0 次',
          color: Colors.orange,
        )),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '今日活动',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('查看全部'),
                ),
              ],
            ),
            const Divider(),
            ..._activities.map((activity) => _buildActivityTile(activity)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(_ActivityItem activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activity.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.status,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${activity.startTime} - ${activity.endTime}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.duration,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据统计',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDataItem(
                    Icons.storage,
                    '本地记录',
                    '156 条',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildDataItem(
                    Icons.cloud_upload,
                    '待上传',
                    '$_pendingCount 条',
                    _pendingCount > 0 ? Colors.orange : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildDataItem(
                    Icons.check_circle,
                    '已同步',
                    '128 条',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CameraSetupScreen()),
            ),
            icon: const Icon(Icons.camera_alt),
            label: const Text('摄像头'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
            icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
            label: Text(_isMonitoring ? '停止监控' : '开始监控'),
            style: FilledButton.styleFrom(
              backgroundColor: _isMonitoring 
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  NavigationBar _buildBottomNav() {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          );
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '监控',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: '报告',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: '历史',
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
    final diff = end.difference(start).inMinutes;
    return '$diff 分钟';
  }
}

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildSection(context, '孩子信息', [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('孩子姓名'),
              subtitle: const Text('小明'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.face),
              title: const Text('人脸录入'),
              subtitle: const Text('已录入 1 张'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ]),
          _buildSection(context, '提醒设置', [
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text('推送通知'),
              subtitle: const Text('检测到异常时推送'),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              secondary: const Icon(Icons.email),
              title: const Text('邮件提醒'),
              subtitle: const Text('parent@example.com'),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              secondary: const Icon(Icons.volume_up),
              title: const Text('声音提醒'),
              subtitle: const Text('检测到异常时播放声音'),
              value: true,
              onChanged: (v) {},
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('离开提醒阈值'),
              subtitle: const Text('15 分钟'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('边玩边学阈值'),
              subtitle: const Text('5 分钟'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ]),
          _buildSection(context, '数据同步', [
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('服务器地址'),
              subtitle: const Text('http://192.168.1.100:8000'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('自动同步'),
              subtitle: const Text('每 5 分钟'),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
            ListTile(
              leading: const Icon(Icons.wifi),
              title: const Text('仅 WiFi 上传'),
              subtitle: const Text('节省移动流量'),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
          ]),
          _buildSection(context, '存储', [
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('本地存储'),
              subtitle: const Text('12.5 MB 已使用'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('清除缓存'),
              subtitle: const Text('释放存储空间'),
              onTap: () {},
            ),
          ]),
          _buildSection(context, '关于', [
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('版本'),
              subtitle: Text('1.0.0 (Build 1)'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
}

/// 摄像头设置页面
class CameraSetupScreen extends StatelessWidget {
  const CameraSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('摄像头设置'),
      ),
      body: ListView(
        children: [
          Container(
            height: 250,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                  SizedBox(height: 8),
                  Text('摄像头未开启', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('选择摄像头', style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.camera_front),
            title: const Text('前置摄像头'),
            subtitle: const Text('推荐用于监控'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.camera_rear),
            title: const Text('后置摄像头'),
            subtitle: const Text('可用于拍摄桌面'),
            onTap: () {},
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('视频质量', style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.hd),
            title: const Text('高清 (720p)'),
            subtitle: const Text('推荐 - 平衡清晰度和性能'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.four_k),
            title: const Text('超清 (1080p)'),
            subtitle: const Text('更高清晰度，更多流量'),
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
              label: const Text('预览摄像头'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('今日概览', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(context, '2.5h', '学习时长', Colors.blue),
                      _buildStat(context, '85%', '专注度', Colors.green),
                      _buildStat(context, '3次', '离开', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('本周趋势', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  SizedBox(height: 150, child: _buildWeekChart()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildWeekChart() {
    final data = [0.6, 0.8, 0.5, 0.9, 0.7, 0.4, 0.3];
    final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(width: 28, height: 100 * data[i], decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Text(days[i], style: const TextStyle(fontSize: 10)),
        ],
      )),
    );
  }
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
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text('2024-02-${20 - index}'),
            subtitle: Text('学习 ${2 + index * 0.5} 小时 • 专注度 ${70 + index}%'),
            trailing: const Icon(Icons.chevron_right),
          );
        },
      ),
    );
  }
}
