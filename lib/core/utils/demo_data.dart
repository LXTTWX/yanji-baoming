import 'package:yanji/core/constants/app_constants.dart';
import 'package:yanji/data/models/family_member.dart';
import 'package:yanji/data/models/fitness_record.dart';
import 'package:yanji/data/models/health_record.dart';
import 'package:yanji/data/models/reminder.dart';
import 'package:yanji/data/models/user_profile.dart';
import 'package:yanji/data/repositories/emergency_card_repository.dart';
import 'package:yanji/data/repositories/family_member_repository.dart';
import 'package:yanji/data/repositories/fitness_record_repository.dart';
import 'package:yanji/data/repositories/health_record_repository.dart';
import 'package:yanji/data/repositories/reminder_repository.dart';
import 'package:yanji/data/repositories/user_profile_repository.dart';

/// 演示数据生成器
/// 生成真实的演示数据，覆盖所有模块功能展示
class DemoData {
  final UserProfileRepository _profileRepo = UserProfileRepository();
  final FitnessRecordRepository _fitnessRepo = FitnessRecordRepository();
  final FamilyMemberRepository _familyRepo = FamilyMemberRepository();
  final HealthRecordRepository _healthRepo = HealthRecordRepository();
  final ReminderRepository _reminderRepo = ReminderRepository();
  final EmergencyCardRepository _emergencyRepo = EmergencyCardRepository();

  /// 加载全部演示数据
  Future<void> loadAll() async {
    await _clearAllData();
    await _loadUserProfile();
    await _loadFitnessRecords();
    await _loadFamilyMembers();
    await _loadHealthRecords();
    await _loadReminders();
    await _emergencyRepo.initDemoData();
  }

  /// 清空所有数据
  Future<void> _clearAllData() async {
    final profile = await _profileRepo.getProfile();
    if (profile != null) {
      await _profileRepo.deleteProfile(profile.id);
    }

    final fitnessRecords = await _fitnessRepo.getAllRecords();
    for (final r in fitnessRecords) {
      await _fitnessRepo.deleteRecord(r.id);
    }

    final members = await _familyRepo.getAllMembers();
    for (final m in members) {
      await _familyRepo.deleteMember(m.id);
    }

    final healthRecords = await _healthRepo.getAllRecords();
    for (final r in healthRecords) {
      await _healthRepo.deleteRecord(r.id);
    }

    final reminders = await _reminderRepo.getAllReminders();
    for (final r in reminders) {
      await _reminderRepo.deleteReminder(r.id);
    }
  }

  /// 加载用户资料：身高175cm，体重70kg
  Future<void> _loadUserProfile() async {
    final now = DateTime.now();
    final profile = UserProfile(
      id: AppConstants.demoUserId,
      nickname: '演示用户',
      age: 32,
      gender: 1,
      height: 175,
      weight: 70,
      elderMode: false,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );
    await _profileRepo.saveProfile(profile);
  }

  /// 加载健身打卡记录：14天记录，连续7天打卡，累计12天完成
  Future<void> _loadFitnessRecords() async {
    final now = DateTime.now();
    final plans = ['居家减脂', '徒手增肌', '肩颈放松'];

    // 最近7天连续打卡（全部完成）
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final planIndex = i % 3;
      final duration = planIndex == 2 ? 20 : (planIndex == 0 ? 30 : 45);
      final calories = planIndex == 2 ? 120.0 : (planIndex == 0 ? 250.0 : 320.0);

      await _fitnessRepo.addRecord(FitnessRecord(
        id: 'demo_fitness_c$i',
        planType: plans[planIndex],
        duration: duration,
        calories: calories,
        date: dateStr,
        completed: true,
        createdAt: date.toIso8601String(),
      ));
    }

    // 再往前推14天，其中5天完成、5天未完成、4天无记录
    final completedOffsets = [8, 9, 11, 13, 15];
    final failedOffsets = [10, 12, 14, 16, 18];

    for (final offset in completedOffsets) {
      final date = now.subtract(Duration(days: offset));
      final dateStr = date.toIso8601String().substring(0, 10);
      final planIndex = offset % 3;
      final duration = planIndex == 2 ? 20 : (planIndex == 0 ? 30 : 45);
      final calories = planIndex == 2 ? 100.0 : (planIndex == 0 ? 220.0 : 300.0);

      await _fitnessRepo.addRecord(FitnessRecord(
        id: 'demo_fitness_a$offset',
        planType: plans[planIndex],
        duration: duration,
        calories: calories,
        date: dateStr,
        completed: true,
        createdAt: date.toIso8601String(),
      ));
    }

    for (final offset in failedOffsets) {
      final date = now.subtract(Duration(days: offset));
      final dateStr = date.toIso8601String().substring(0, 10);

      await _fitnessRepo.addRecord(FitnessRecord(
        id: 'demo_fitness_b$offset',
        planType: plans[offset % 3],
        duration: 0,
        calories: 0,
        date: dateStr,
        completed: false,
        createdAt: date.toIso8601String(),
      ));
    }
  }

  /// 加载3位家庭成员
  Future<void> _loadFamilyMembers() async {
    final now = DateTime.now().toIso8601String();

    // 爸爸：65岁，有高血压
    await _familyRepo.addMember(FamilyMember(
      id: 'demo_dad',
      name: '爸爸',
      relationship: '父亲',
      age: 65,
      gender: 1,
      phone: '13800138001',
      note: '高血压病史，需定期监测血压',
      createdAt: now,
    ));

    // 妈妈：62岁，身体基本健康
    await _familyRepo.addMember(FamilyMember(
      id: 'demo_mom',
      name: '妈妈',
      relationship: '母亲',
      age: 62,
      gender: 2,
      phone: '13800138002',
      createdAt: now,
    ));

    // 爷爷：78岁，心率偏慢
    await _familyRepo.addMember(FamilyMember(
      id: 'demo_grandpa',
      name: '爷爷',
      relationship: '爷爷',
      age: 78,
      gender: 1,
      phone: '13800138003',
      note: '年龄较大，需关注心率',
      createdAt: now,
    ));
  }

  /// 加载30天健康记录：每位成员包含正常+异常数据
  Future<void> _loadHealthRecords() async {
    // 爸爸的记录：血压偏高（高血压1级/2级混合），心率正常偏高
    await _loadMemberHealthRecords(
      memberId: 'demo_dad',
      days: 30,
      systolicRange: [138, 165], // 包含正常和高血压范围
      diastolicRange: [85, 102],
      heartRateRange: [72, 98],
      abnormalRatio: 0.4, // 40%异常率
    );

    // 妈妈的记录：血压基本正常，偶有偏高
    await _loadMemberHealthRecords(
      memberId: 'demo_mom',
      days: 30,
      systolicRange: [118, 142],
      diastolicRange: [72, 92],
      heartRateRange: [65, 88],
      abnormalRatio: 0.15, // 15%异常率
    );

    // 爷爷的记录：心率偏慢，血压偏高
    await _loadMemberHealthRecords(
      memberId: 'demo_grandpa',
      days: 30,
      systolicRange: [130, 158],
      diastolicRange: [80, 96],
      heartRateRange: [52, 75], // 心率偏慢
      abnormalRatio: 0.35, // 35%异常率
    );
  }

  /// 为单个成员加载健康记录
  Future<void> _loadMemberHealthRecords({
    required String memberId,
    required int days,
    required List<int> systolicRange,
    required List<int> diastolicRange,
    required List<int> heartRateRange,
    required double abnormalRatio,
  }) async {
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      // 每隔1-2天记录一次，不是每天都有
      if (i % 2 != 0 && i > 3) continue;

      final date = now.subtract(Duration(days: i));
      final hour = 7 + (i % 3); // 7-9点之间测量
      final measuredAt = DateTime(date.year, date.month, date.day, hour, 15 + (i * 7) % 45);

      // 生成血压数据，按比例产生异常
      final isAbnormalDay = (i * 17 + 3) % 100 < (abnormalRatio * 100).toInt();
      final systolic = isAbnormalDay
          ? systolicRange[1] + (i % 8) // 超出上限
          : systolicRange[0] + (i * 3) % (systolicRange[1] - systolicRange[0] - 5);
      final diastolic = isAbnormalDay
          ? diastolicRange[1] + (i % 5) // 超出上限
          : diastolicRange[0] + (i * 2) % (diastolicRange[1] - diastolicRange[0] - 3);

      final isBpAbnormal = systolic >= 140 || diastolic >= 90;
      String? bpDesc;
      if (systolic >= 160 || diastolic >= 100) {
        bpDesc = '血压明显升高（高血压2级），请尽快就医，遵医嘱服药';
      } else if (systolic >= 140 || diastolic >= 90) {
        bpDesc = '血压轻度升高（高血压1级），建议低盐饮食、规律作息，定期监测';
      }

      await _healthRepo.addRecord(HealthRecord(
        id: 'demo_bp_${memberId}_$i',
        memberId: memberId,
        type: '血压',
        value: '$systolic/$diastolic',
        unit: 'mmHg',
        isAbnormal: isBpAbnormal,
        abnormalDesc: bpDesc,
        measuredAt: measuredAt.toIso8601String(),
        createdAt: measuredAt.toIso8601String(),
      ));

      // 心率数据
      final heartRate = heartRateRange[0] + (i * 5) % (heartRateRange[1] - heartRateRange[0]);
      final isHrAbnormal = heartRate < 60 || heartRate > 100;
      String? hrDesc;
      if (heartRate < 60) {
        hrDesc = '心率偏慢，如伴有头晕乏力建议就医检查';
      } else if (heartRate > 100) {
        hrDesc = '心率偏快，建议避免剧烈运动，保持情绪稳定';
      }

      await _healthRepo.addRecord(HealthRecord(
        id: 'demo_hr_${memberId}_$i',
        memberId: memberId,
        type: '心率',
        value: heartRate.toString(),
        unit: '次/分钟',
        isAbnormal: isHrAbnormal,
        abnormalDesc: hrDesc,
        measuredAt: measuredAt.toIso8601String(),
        createdAt: measuredAt.toIso8601String(),
      ));
    }
  }

  /// 加载4个提醒
  Future<void> _loadReminders() async {
    final now = DateTime.now().toIso8601String();

    await _reminderRepo.addReminder(Reminder(
      id: 'demo_reminder_water',
      type: '喝水',
      title: '喝水提醒',
      content: '适量饮水，保持身体水分充足',
      time: '08:00',
      repeatRule: '每天',
      enabled: true,
      createdAt: now,
    ));

    await _reminderRepo.addReminder(Reminder(
      id: 'demo_reminder_fitness',
      type: '健身训练',
      title: '该锻炼啦',
      content: '坚持运动，保持健康体魄',
      time: '19:00',
      repeatRule: '工作日',
      enabled: true,
      createdAt: now,
    ));

    await _reminderRepo.addReminder(Reminder(
      id: 'demo_reminder_bp',
      type: '测血压',
      title: '请测量血压',
      content: '定时测量血压，关注心血管健康',
      time: '09:00',
      repeatRule: '每天',
      enabled: true,
      memberId: 'demo_dad',
      createdAt: now,
    ));

    await _reminderRepo.addReminder(Reminder(
      id: 'demo_reminder_med',
      type: '服药',
      title: '该吃药了',
      content: '按时服药，不要忘记哦',
      time: '20:00',
      repeatRule: '每天',
      enabled: true,
      memberId: 'demo_dad',
      createdAt: now,
    ));
  }
}
