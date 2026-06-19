import 'package:flutter/widgets.dart';
import 'package:yanji/data/repositories/app_config_repository.dart';

/// 应用锁定状态管理
///
/// 职责：
/// 1. 启动时根据 appLockEnabled 决定是否需要解锁
/// 2. 监听前后台切换，超过 autoLockTime 自动锁定
/// 3. 提供 isLocked 状态供 UI 响应
class AppLockProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AppConfigRepository _configRepo = AppConfigRepository();

  /// 是否需要显示锁屏（启动锁或自动锁定触发）
  bool _isLocked = false;

  /// 应用启动锁是否启用
  bool _appLockEnabled = false;

  /// 自动锁定时间（秒，0表示从不）
  int _autoLockTime = 0;

  /// 上次进入后台的时间戳
  DateTime? _backgroundedAt;

  /// 是否已初始化
  bool _initialized = false;

  /// 是否处于锁定状态
  bool get isLocked => _isLocked;

  /// 启动锁是否启用
  bool get appLockEnabled => _appLockEnabled;

  /// 构造函数
  AppLockProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// 初始化：读取配置，决定启动时是否锁定
  Future<void> init() async {
    if (_initialized) return;
    final config = await _configRepo.getConfig();
    _appLockEnabled = config.appLockEnabled;
    _autoLockTime = config.autoLockTime;
    // 启动锁启用时，冷启动即锁定
    _isLocked = _appLockEnabled;
    _initialized = true;
    notifyListeners();
  }

  /// 刷新配置（设置页修改后调用）
  Future<void> refreshConfig() async {
    final config = await _configRepo.getConfig();
    _appLockEnabled = config.appLockEnabled;
    _autoLockTime = config.autoLockTime;
    // 关闭启动锁时，解除锁定
    if (!_appLockEnabled) {
      _isLocked = false;
    }
    notifyListeners();
  }

  /// 解锁（验证通过后调用）
  void unlock() {
    _isLocked = false;
    notifyListeners();
  }

  /// 手动锁定（如设置密码后立即锁定测试）
  void lock() {
    if (_appLockEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_appLockEnabled) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 进入后台，记录时间
        _backgroundedAt = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        // 从后台恢复，检查是否超时
        _checkAutoLock();
        break;
      default:
        break;
    }
  }

  /// 检查是否需要自动锁定
  void _checkAutoLock() {
    if (!_appLockEnabled || _autoLockTime <= 0) {
      _backgroundedAt = null;
      return;
    }
    final bgAt = _backgroundedAt;
    if (bgAt == null) return;
    final elapsed = DateTime.now().difference(bgAt).inSeconds;
    if (elapsed >= _autoLockTime) {
      _isLocked = true;
      notifyListeners();
    }
    _backgroundedAt = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
