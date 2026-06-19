import 'package:hive/hive.dart';
import 'package:yanji/core/constants/app_constants.dart';
import 'package:yanji/data/models/fitness_record.dart';

/// 健身记录仓库
class FitnessRecordRepository {
  Box<FitnessRecord>? _box;

  /// 获取Hive盒子
  Future<Box<FitnessRecord>> _getBox() async {
    _box ??= await Hive.openBox<FitnessRecord>(AppConstants.boxFitnessRecord);
    return _box!;
  }

  /// 获取所有健身记录
  Future<List<FitnessRecord>> getAllRecords() async {
    final box = await _getBox();
    return box.values.toList();
  }

  /// 获取指定日期的记录
  Future<List<FitnessRecord>> getRecordsByDate(String date) async {
    final box = await _getBox();
    return box.values.where((r) => r.date == date).toList();
  }

  /// 获取连续打卡天数
  Future<int> getConsecutiveDays() async {
    final box = await _getBox();
    final records = box.values.where((r) => r.completed).toList();
    if (records.isEmpty) return 0;
    
    records.sort((a, b) => b.date.compareTo(a.date));
    int consecutive = 0;
    String? lastDate;
    
    for (final record in records) {
      if (lastDate == null) {
        lastDate = record.date;
        consecutive = 1;
      } else {
        final last = DateTime.parse(lastDate);
        final current = DateTime.parse(record.date);
        final diff = last.difference(current).inDays;
        if (diff == 1) {
          consecutive++;
          lastDate = record.date;
        } else {
          break;
        }
      }
    }
    return consecutive;
  }

  /// 添加健身记录
  Future<void> addRecord(FitnessRecord record) async {
    final box = await _getBox();
    await box.put(record.id, record);
  }

  /// 更新健身记录
  Future<void> updateRecord(FitnessRecord record) async {
    final box = await _getBox();
    await box.put(record.id, record);
  }

  /// 删除健身记录
  Future<void> deleteRecord(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  /// 初始化演示数据
  Future<void> initDemoData() async {
    final box = await _getBox();
    if (box.isEmpty) {
      final now = DateTime.now();
      final demoRecords = [
        FitnessRecord(
          id: 'demo_fitness_1',
          planType: '居家减脂',
          duration: 30,
          calories: 250,
          date: now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
          completed: true,
          createdAt: now.toIso8601String(),
        ),
        FitnessRecord(
          id: 'demo_fitness_2',
          planType: '徒手增肌',
          duration: 45,
          calories: 320,
          date: now.toIso8601String().substring(0, 10),
          completed: true,
          createdAt: now.toIso8601String(),
        ),
      ];
      for (final record in demoRecords) {
        await box.put(record.id, record);
      }
    }
  }
}
