import 'package:hive/hive.dart';

/// 用户资料模型
@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  /// 用户ID
  @HiveField(0)
  final String id;

  /// 用户昵称
  @HiveField(1)
  String nickname;

  /// 年龄
  @HiveField(2)
  int? age;

  /// 性别（0-未知，1-男，2-女）
  @HiveField(3)
  int gender;

  /// 身高（厘米）
  @HiveField(4)
  double? height;

  /// 体重（千克）
  @HiveField(5)
  double? weight;

  /// 是否开启长辈模式
  @HiveField(6)
  bool elderMode;

  /// 创建时间
  @HiveField(7)
  final String createdAt;

  /// 更新时间
  @HiveField(8)
  String updatedAt;

  /// 构造函数
  UserProfile({
    required this.id,
    this.nickname = '用户',
    this.age,
    this.gender = 0,
    this.height,
    this.weight,
    this.elderMode = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 计算BMI值（BMI = 体重kg / 身高m²）
  double? calculateBMI() {
    final h = height;
    final w = weight;
    if (h != null && w != null && h > 0) {
      final heightInM = h / 100;
      return w / (heightInM * heightInM);
    }
    return null;
  }

  /// 创建演示用户
  factory UserProfile.demo() {
    final now = DateTime.now().toIso8601String();
    return UserProfile(
      id: 'demo_user_001',
      nickname: '演示用户',
      age: 30,
      gender: 1,
      height: 170,
      weight: 65,
      elderMode: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}
