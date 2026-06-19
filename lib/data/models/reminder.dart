import 'package:hive/hive.dart';

/// 提醒模型
@HiveType(typeId: 4)
class Reminder extends HiveObject {
  /// 提醒ID
  @HiveField(0)
  final String id;

  /// 提醒类型（健身/喝水/测压/服药）
  @HiveField(1)
  String type;

  /// 提醒标题
  @HiveField(2)
  String title;

  /// 提醒内容
  @HiveField(3)
  String content;

  /// 提醒时间（HH:mm格式）
  @HiveField(4)
  String time;

  /// 重复规则（每天/工作日/周末/自定义）
  @HiveField(5)
  String repeatRule;

  /// 是否启用
  @HiveField(6)
  bool enabled;

  /// 关联成员ID（可选）
  @HiveField(7)
  String? memberId;

  /// 创建时间
  @HiveField(8)
  final String createdAt;

  /// 构造函数
  Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.time,
    this.repeatRule = '每天',
    this.enabled = true,
    this.memberId,
    required this.createdAt,
  });
}
