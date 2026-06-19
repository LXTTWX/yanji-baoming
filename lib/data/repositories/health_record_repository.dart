import 'package:hive/hive.dart';
import 'package:yanji/core/constants/app_constants.dart';
import 'package:yanji/data/models/health_record.dart';

/// 健康记录仓库
class HealthRecordRepository {
  Box<HealthRecord>? _box;

  /// 获取Hive盒子
  Future<Box<HealthRecord>> _getBox() async {
    _box ??= await Hive.openBox<HealthRecord>(AppConstants.boxHealthRecord);
    return _box!;
  }

  /// 获取所有健康记录
  Future<List<HealthRecord>> getAllRecords() async {
    final box = await _getBox();
    return box.values.toList();
  }

  /// 获取指定成员的健康记录
  Future<List<HealthRecord>> getRecordsByMember(String memberId) async {
    final box = await _getBox();
    return box.values.where((r) => r.memberId == memberId).toList();
  }

  /// 获取指定类型的记录
  Future<List<HealthRecord>> getRecordsByType(String type) async {
    final box = await _getBox();
    return box.values.where((r) => r.type == type).toList();
  }

  /// 获取异常记录
  Future<List<HealthRecord>> getAbnormalRecords() async {
    final box = await _getBox();
    return box.values.where((r) => r.isAbnormal).toList();
  }

  /// 添加健康记录
  Future<void> addRecord(HealthRecord record) async {
    final box = await _getBox();
    await box.put(record.id, record);
  }

  /// 更新健康记录
  Future<void> updateRecord(HealthRecord record) async {
    final box = await _getBox();
    await box.put(record.id, record);
  }

  /// 删除健康记录
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
        HealthRecord(
          id: 'demo_health_1',
          memberId: 'demo_member_1',
          type: '血压',
          value: '{"systolic": 135, "diastolic": 85}',
          unit: 'mmHg',
          isAbnormal: true,
          abnormalDesc: '收缩压偏高，建议注意休息，减少盐分摄入',
          measuredAt: now.toIso8601String(),
          createdAt: now.toIso8601String(),
        ),
        HealthRecord(
          id: 'demo_health_2',
          memberId: 'demo_member_1',
          type: '心率',
          value: '72',
          unit: '次/分钟',
          isAbnormal: false,
          measuredAt: now.toIso8601String(),
          createdAt: now.toIso8601String(),
        ),
      ];
      for (final record in demoRecords) {
        await box.put(record.id, record);
      }
    }
  }
}
