import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:yanji/core/constants/app_constants.dart';
import 'package:yanji/core/providers/app_lock_provider.dart';
import 'package:yanji/core/providers/theme_provider.dart';
import 'package:yanji/core/router/app_router.dart';
import 'package:yanji/core/utils/demo_data.dart';
import 'package:yanji/data/adapters/hive_adapters.dart';
import 'package:yanji/data/repositories/app_config_repository.dart';
import 'package:yanji/data/repositories/user_profile_repository.dart';
import 'package:yanji/modules/reminder/notification_helper.dart';
import 'package:yanji/modules/settings/lock_page.dart';

/// 全局导航Key，用于在非Widget上下文中显示弹窗
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 应用入口
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局错误边界：捕获任何未处理的渲染错误，避免红屏
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('页面加载异常，请返回重试',
                  style: TextStyle(fontSize: 16)),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(details.exception.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  };

  // 初始化Hive
  await Hive.initFlutter();

  // 注册Hive适配器（手写适配器，避免build_runner依赖）
  _registerHiveAdapters();

  // 初始化主题配置
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // 初始化应用锁配置（启动锁 + 自动锁定）
  final appLockProvider = AppLockProvider();
  await appLockProvider.init();

  // 首次启动检测：无数据时自动加载演示数据
  await _checkFirstLaunch();

  // 初始化本地通知（非Web端）
  if (!kIsWeb) {
    await NotificationHelper().init();
    await NotificationHelper().requestPermission();
  }

  runApp(MyApp(
    themeProvider: themeProvider,
    appLockProvider: appLockProvider,
  ));
}

/// 注册所有Hive适配器
void _registerHiveAdapters() {
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(FitnessRecordAdapter());
  Hive.registerAdapter(FamilyMemberAdapter());
  Hive.registerAdapter(HealthRecordAdapter());
  Hive.registerAdapter(ReminderAdapter());
  Hive.registerAdapter(AppConfigAdapter());
  Hive.registerAdapter(EmergencyContactAdapter());
  Hive.registerAdapter(EmergencyCardAdapter());
}

/// 首次启动检测
/// 如果AppConfig.isFirstLaunch为true且无用户数据，则自动加载演示数据
Future<void> _checkFirstLaunch() async {
  try {
    final configRepo = AppConfigRepository();
    final config = await configRepo.getConfig();

    if (config.isFirstLaunch) {
      // 检查是否有用户数据
      final profile = await UserProfileRepository().getProfile();
      if (profile == null) {
        // 无数据，自动加载演示数据
        await DemoData().loadAll();
      }
      // 标记已启动
      await configRepo.markLaunched();
    }
  } catch (e) {
    debugPrint('首次启动检测失败: $e');
  }
}

/// 应用根组件
class MyApp extends StatefulWidget {
  /// 主题状态管理
  final ThemeProvider themeProvider;

  /// 应用锁状态管理
  final AppLockProvider appLockProvider;

  /// 构造函数
  const MyApp({
    super.key,
    required this.themeProvider,
    required this.appLockProvider,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

/// 应用根组件状态
///
/// 监听系统无障碍设置变化（字体缩放/高对比度/减少动画），
/// 通过 [ThemeProvider.setSystemAccessibility] 注入，使 App 能跟随系统。
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 初始注入一次系统无障碍状态
    _pushSystemAccessibility();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 系统设置变化时触发
  @override
  void didChangeMetrics() {
    _pushSystemAccessibility();
  }

  /// 系统无障碍设置变化时触发
  @override
  void didChangeAccessibilityFeatures() {
    _pushSystemAccessibility();
  }

  /// 读取系统当前无障碍状态并注入 ThemeProvider
  void _pushSystemAccessibility() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final mediaQueryData = MediaQueryData.fromView(view);
    widget.themeProvider.setSystemAccessibility(
      textScale: mediaQueryData.textScaler.scale(1.0),
      highContrast: mediaQueryData.highContrast,
      reduceMotion: mediaQueryData.accessibleNavigation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: widget.themeProvider),
        ChangeNotifierProvider<AppLockProvider>.value(value: widget.appLockProvider),
      ],
      child: Consumer2<ThemeProvider, AppLockProvider>(
        builder: (context, themeProvider, appLockProvider, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(themeProvider.fontScale),
              // 减少动画模式下，禁用平台动画
              accessibleNavigation: themeProvider.reduceMotion ||
                  MediaQuery.of(context).accessibleNavigation,
            ),
            child: MaterialApp.router(
              title: AppConstants.appName,
              theme: themeProvider.theme,
              routerConfig: AppRouter.router,
              debugShowCheckedModeBanner: false,
              builder: (context, routerChild) {
                // 背景装饰层（玻璃光斑/羊皮纸纹理）位于底层，
                // 上层为路由 Navigator。Scaffold 背景透明即可透出装饰。
                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: themeProvider.reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: themeProvider.backgroundWidget,
                      ),
                    ),
                    Positioned.fill(child: routerChild ?? const SizedBox.shrink()),
                    // 启动锁 / 自动锁定遮罩：锁定时覆盖整个应用
                    if (appLockProvider.isLocked)
                      Positioned.fill(
                        child: LockPage(
                          mode: LockMode.verify,
                          onUnlocked: () => appLockProvider.unlock(),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
