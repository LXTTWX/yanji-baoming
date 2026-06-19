import 'package:hive/hive.dart';

/// 家庭成员模型
@HiveType(typeId: 2)
class FamilyMember extends HiveObject {
  /// 成员ID
  @HiveField(0)
  final String id;

  /// 成员姓名
  @HiveField(1)
  String name;

  /// 与用户关系
  @HiveField(2)
  String relationship;

  /// 年龄
  @HiveField(3)
  int? age;

  /// 性别（0-未知，1-男，2-女）
  @HiveField(4)
  int gender;

  /// 联系电话
  @HiveField(5)
  String? phone;

  /// 备注
  @HiveField(6)
  String? note;

  /// 创建时间
  @HiveField(7)
  final String createdAt;

  /// 构造函数
  FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.age,
    this.gender = 0,
    this.phone,
    this.note,
    required this.createdAt,
  });
}
