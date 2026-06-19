import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:yanji/data/models/reminder.dart';
import 'package:yanji/modules/reminder/reminder_constants.dart';

/// 本地通知辅助类（Web端自动降级为空操作）
class NotificationHelper {
  /// 单例实例
  static final NotificationHelper _instance = NotificationHelper._internal();
  /// 工厂构造函数
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 初始化通知插件（Web端跳过）
  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    
    try {
      // 初始化时区数据
      tz_data.initializeTimeZones();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const windowsSettings = WindowsInitializationSettings(
        appName: '家檐安记',
        appUserModelId: 'com.yanji.app',
        guid: 'd49b2e44-4e4a-4e4a-4e4a-4e4a4e4a4e4a',
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        windows: windowsSettings,
      );
      
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      debugPrint('通知初始化失败: $e');
    }
  }

  /// 请求通知权限
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('请求通知权限失败: $e');
      return false;
    }
  }

  /// 为提醒安排通知（Web端跳过）
  Future<void> scheduleReminder(Reminder reminder) async {
    if (kIsWeb || !reminder.enabled) return;
    if (!_initialized) await init();

    try {
      // 取消旧通知
      await cancelReminder(reminder.id);
      
      // 解析时间
      final parts = reminder.time.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;
      
      // 解析重复天数
      final selectedDays = _parseRepeatDays(reminder.repeatRule);
      
      // 为每一天安排通知
      for (int i = 0; i < 7; i++) {
        if (!selectedDays[i]) continue;
        
        // Flutter的weekday: 1=周一, 7=周日
        final weekday = i + 1;
        final notificationId = _getNotificationId(reminder.id, i);
        
        await _plugin.zonedSchedule(
          notificationId,
          reminder.title,
          reminder.content,
          _nextInstanceOfWeekdayTime(weekday, hour, minute),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'yanji_reminder',
              '提醒通知',
              channelDescription: '家檐安记提醒通知',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
            windows: const WindowsNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      debugPrint('安排通知失败: $e');
    }
  }

  /// 取消提醒的通知
  Future<void> cancelReminder(String reminderId) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    try {
      // 取消该提醒的所有7个通知
      for (int i = 0; i < 7; i++) {
        final notificationId = _getNotificationId(reminderId, i);
        await _plugin.cancel(notificationId);
      }
    } catch (e) {
      debugPrint('取消通知失败: $e');
    }
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('取消所有通知失败: $e');
    }
  }

  /// 计算通知ID（基于提醒ID和星期索引）
  int _getNotificationId(String reminderId, int dayIndex) {
    // 简单哈希：取reminderId的hashCode + dayIndex
    return (reminderId.hashCode.abs() % 100000) * 10 + dayIndex;
  }

  /// 获取下一个指定星期几+时间的时刻
  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// 解析重复规则为7天选中状态
  List<bool> _parseRepeatDays(String rule) {
    final days = List<bool>.filled(7, false);
    
    if (rule == '每天') {
      for (int i = 0; i < 7; i++) {
        days[i] = true;
      }
      return days;
    }
    if (rule == '工作日') {
      for (int i = 0; i < 5; i++) {
        days[i] = true;
      }
      return days;
    }
    if (rule == '周末') {
      days[5] = true;
      days[6] = true;
      return days;
    }

    // 解析自定义 "周一,周三,周五" 格式
    final parts = rule.split(',');
    for (final part in parts) {
      final index = ReminderConstants.weekdays.indexOf(part.trim());
      if (index >= 0) {
        days[index] = true;
      }
    }
    return days;
  }
}
