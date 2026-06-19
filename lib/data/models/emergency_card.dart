import 'package:hive/hive.dart';

/// 紧急联系人模型
///
/// 用于急救卡中的紧急联系人信息。
/// 独立于 FamilyMember，因为急救联系人可能是家人、医生或朋友。
@HiveType(typeId: 6)
class EmergencyContact extends HiveObject {
  /// 联系人ID
  @HiveField(0)
  final String id;

  /// 联系人姓名
  @HiveField(1)
  String name;

  /// 与用户关系（如：父亲、配偶、家庭医生）
  @HiveField(2)
  String relationship;

  /// 联系电话
  @HiveField(3)
  String phone;

  /// 是否为第一紧急联系人（急救时优先联系）
  @HiveField(4)
  bool isPrimary;

  /// 备注（如：知道我的用药情况）
  @HiveField(5)
  String? note;

  /// 创建时间
  @HiveField(6)
  final String createdAt;

  /// 构造函数
  EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.isPrimary = false,
    this.note,
    required this.createdAt,
  });
}

/// 急救卡信息模型
///
/// 存储紧急医疗信息。
/// 姓名/生日/身高/体重从 UserProfile 读取，此处不重复存储。
@HiveType(typeId: 7)
class EmergencyCard extends HiveObject {
  /// 急救卡ID（单例，固定为 'emergency_card_main'）
  @HiveField(0)
  final String id;

  /// 血型（0-未知，1-A，2-B，3-AB，4-O）
  @HiveField(1)
  int bloodType;

  /// 过敏史（多条用换行分隔，空字符串表示无）
  @HiveField(2)
  String allergies;

  /// 器官捐献意愿（0-未填写，1-愿意，2-不愿意）
  @HiveField(3)
  int organDonor;

  /// 习惯语言（如：普通话、粤语、英语）
  @HiveField(4)
  String preferredLanguage;

  /// 其他医疗备注（如：起搏器、糖尿病史、手术史）
  @HiveField(5)
  String medicalNotes;

  /// 更新时间
  @HiveField(6)
  String updatedAt;

  /// 构造函数
  EmergencyCard({
    required this.id,
    this.bloodType = 0,
    this.allergies = '',
    this.organDonor = 0,
    this.preferredLanguage = '普通话',
    this.medicalNotes = '',
    required this.updatedAt,
  });

  /// 创建默认急救卡
  factory EmergencyCard.defaultCard() {
    return EmergencyCard(
      id: 'emergency_card_main',
      bloodType: 0,
      allergies: '',
      organDonor: 0,
      preferredLanguage: '普通话',
      medicalNotes: '',
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}
