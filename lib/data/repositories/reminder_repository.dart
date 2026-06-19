import 'package:hive/hive.dart';
import 'package:yanji/core/constants/app_constants.dart';
import 'package:yanji/data/models/reminder.dart';

/// 提醒仓库
class ReminderRepository {
  Box<Reminder>? _box;

  /// 获取Hive盒子
  Future<Box<Reminder>> _getBox() async {
    _box ??= await Hive.openBox<Reminder>(AppConstants.boxReminder);
    return _box!;
  }

  /// 获取所有提醒
  Future<List<Reminder>> getAllReminders() async {
    final box = await _getBox();
    return box.values.toList();
  }

  /// 获取启用的提醒
  Future<List<Reminder>> getEnabledReminders() async {
    final box = await _getBox();
    return box.values.where((r) => r.enabled).toList();
  }

  /// 获取指定类型的提醒
  Future<List<Reminder>> getRemindersByType(String type) async {
    final box = await _getBox();
    return box.values.where((r) => r.type == type).toList();
  }

  /// 添加提醒
  Future<void> addReminder(Reminder reminder) async {
    final box = await _getBox();
    await box.put(reminder.id, reminder);
  }

  /// 更新提醒
  Future<void> updateReminder(Reminder reminder) async {
    final box = await _getBox();
    await box.put(reminder.id, reminder);
  }

  /// 删除提醒
  Future<void> deleteReminder(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  /// 切换提醒状态
  Future<void> toggleReminder(String id) async {
    final box = await _getBox();
    final reminder = box.get(id);
    if (reminder != null) {
      reminder.enabled = !reminder.enabled;
      await reminder.save();
    }
  }

  /// 初始化演示数据
  Future<void> initDemoData() async {
    final box = await _getBox();
    if (box.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final demoReminders = [
        Reminder(
          id: 'demo_reminder_1',
          type: '喝水',
          title: '喝水提醒',
          content: '该喝水了，保持身体水分充足',
          time: '09:00',
          repeatRule: '每天',
          enabled: true,
          createdAt: now,
        ),
        Reminder(
          id: 'demo_reminder_2',
          type: '测压',
          title: '血压测量提醒',
          content: '请测量今日血压并记录',
          time: '08:00',
          repeatRule: '每天',
          enabled: true,
          memberId: 'demo_member_1',
          createdAt: now,
        ),
      ];
      for (final reminder in demoReminders) {
        await box.put(reminder.id, reminder);
      }
    }
  }
}
