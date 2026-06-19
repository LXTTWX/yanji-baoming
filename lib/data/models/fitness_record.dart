import 'package:hive/hive.dart';

/// 健身记录模型
@HiveType(typeId: 1)
class FitnessRecord extends HiveObject {
  /// 记录ID
  @HiveField(0)
  final String id;

  /// 计划类型（居家减脂/徒手增肌/肩颈放松）
  @HiveField(1)
  String planType;

  /// 训练时长（分钟）
  @HiveField(2)
  int duration;

  /// 消耗卡路里
  @HiveField(3)
  double calories;

  /// 打卡日期（ISO8601格式）
  @HiveField(4)
  String date;

  /// 是否完成
  @HiveField(5)
  bool completed;

  /// 备注
  @HiveField(6)
  String? note;

  /// 创建时间
  @HiveField(7)
  final String createdAt;

  /// 构造函数
  FitnessRecord({
    required this.id,
    required this.planType,
    this.duration = 0,
    this.calories = 0,
    required this.date,
    this.completed = false,
    this.note,
    required this.createdAt,
  });
}
