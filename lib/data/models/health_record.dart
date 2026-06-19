import 'package:hive/hive.dart';

/// 健康记录模型
@HiveType(typeId: 3)
class HealthRecord extends HiveObject {
  /// 记录ID
  @HiveField(0)
  final String id;

  /// 关联成员ID
  @HiveField(1)
  String memberId;

  /// 记录类型（血压/心率/血糖/体温/体重）
  @HiveField(2)
  String type;

  /// 测量值（JSON字符串存储复杂值，如血压的收缩压/舒张压）
  @HiveField(3)
  String value;

  /// 测量单位
  @HiveField(4)
  String unit;

  /// 是否异常
  @HiveField(5)
  bool isAbnormal;

  /// 异常说明
  @HiveField(6)
  String? abnormalDesc;

  /// 测量时间（ISO8601格式）
  @HiveField(7)
  String measuredAt;

  /// 创建时间
  @HiveField(8)
  final String createdAt;

  /// 构造函数
  HealthRecord({
    required this.id,
    required this.memberId,
    required this.type,
    required this.value,
    required this.unit,
    this.isAbnormal = false,
    this.abnormalDesc,
    required this.measuredAt,
    required this.createdAt,
  });
}
