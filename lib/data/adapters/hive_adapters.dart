import 'package:hive/hive.dart';
import 'package:yanji/data/models/user_profile.dart';
import 'package:yanji/data/models/fitness_record.dart';
import 'package:yanji/data/models/family_member.dart';
import 'package:yanji/data/models/health_record.dart';
import 'package:yanji/data/models/reminder.dart';
import 'package:yanji/data/models/app_config.dart';
import 'package:yanji/data/models/emergency_card.dart';

/// UserProfile适配器
class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return UserProfile(
      id: fields[0] as String,
      nickname: fields[1] as String? ?? '用户',
      age: fields[2] as int?,
      gender: fields[3] as int? ?? 0,
      height: fields[4] as double?,
      weight: fields[5] as double?,
      elderMode: fields[6] as bool? ?? false,
      createdAt: fields[7] as String,
      updatedAt: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nickname)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.gender)
      ..writeByte(4)
      ..write(obj.height)
      ..writeByte(5)
      ..write(obj.weight)
      ..writeByte(6)
      ..write(obj.elderMode)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// FitnessRecord适配器
class FitnessRecordAdapter extends TypeAdapter<FitnessRecord> {
  @override
  final int typeId = 1;

  @override
  FitnessRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return FitnessRecord(
      id: fields[0] as String,
      planType: fields[1] as String,
      duration: fields[2] as int? ?? 0,
      calories: fields[3] as double? ?? 0,
      date: fields[4] as String,
      completed: fields[5] as bool? ?? false,
      note: fields[6] as String?,
      createdAt: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FitnessRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.planType)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.calories)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.completed)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FitnessRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// FamilyMember适配器
class FamilyMemberAdapter extends TypeAdapter<FamilyMember> {
  @override
  final int typeId = 2;

  @override
  FamilyMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return FamilyMember(
      id: fields[0] as String,
      name: fields[1] as String,
      relationship: fields[2] as String,
      age: fields[3] as int?,
      gender: fields[4] as int? ?? 0,
      phone: fields[5] as String?,
      note: fields[6] as String?,
      createdAt: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FamilyMember obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.relationship)
      ..writeByte(3)
      ..write(obj.age)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.phone)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// HealthRecord适配器
class HealthRecordAdapter extends TypeAdapter<HealthRecord> {
  @override
  final int typeId = 3;

  @override
  HealthRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HealthRecord(
      id: fields[0] as String,
      memberId: fields[1] as String,
      type: fields[2] as String,
      value: fields[3] as String,
      unit: fields[4] as String,
      isAbnormal: fields[5] as bool? ?? false,
      abnormalDesc: fields[6] as String?,
      measuredAt: fields[7] as String,
      createdAt: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HealthRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.memberId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.isAbnormal)
      ..writeByte(6)
      ..write(obj.abnormalDesc)
      ..writeByte(7)
      ..write(obj.measuredAt)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Reminder适配器
class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 4;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Reminder(
      id: fields[0] as String,
      type: fields[1] as String,
      title: fields[2] as String,
      content: fields[3] as String,
      time: fields[4] as String,
      repeatRule: fields[5] as String? ?? '每天',
      enabled: fields[6] as bool? ?? true,
      memberId: fields[7] as String?,
      createdAt: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.time)
      ..writeByte(5)
      ..write(obj.repeatRule)
      ..writeByte(6)
      ..write(obj.enabled)
      ..writeByte(7)
      ..write(obj.memberId)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// AppConfig适配器
class AppConfigAdapter extends TypeAdapter<AppConfig> {
  @override
  final int typeId = 5;

  @override
  AppConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return AppConfig(
      themeType: fields[0] as int? ?? 0,
      autoTheme: fields[1] as bool? ?? true,
      fontScale: fields[2] as double? ?? 1.0,
      elderMode: fields[3] as bool? ?? false,
      language: fields[4] as String? ?? 'zh_CN',
      isFirstLaunch: fields[5] as bool? ?? true,
      lastSyncAt: fields[6] as String?,
      brightnessMode: fields[7] as int? ?? 0,
      defaultHomePage: fields[8] as int? ?? 0,
      timeFormat: fields[9] as int? ?? 0,
      hypertensionThreshold: fields[10] as int? ?? 140,
      hypotensionThreshold: fields[11] as int? ?? 90,
      heartRateMin: fields[12] as int? ?? 60,
      heartRateMax: fields[13] as int? ?? 100,
      abnormalSensitivity: fields[14] as int? ?? 1,
      showMedicalExplanation: fields[15] as bool? ?? true,
      reminderVibrate: fields[16] as bool? ?? true,
      reminderAdvanceMinutes: fields[17] as int? ?? 0,
      defaultReminderTime: fields[18] as String? ?? '08:00',
      appLockEnabled: fields[19] as bool? ?? false,
      appLockPassword: fields[20] as String?,
      sensitiveDataBlurEnabled: fields[21] as bool? ?? false,
      autoLockTime: fields[22] as int? ?? 0,
      hashedPassword: fields[23] as String?,
      salt: fields[24] as String?,
      lockedUntil: fields[25] as String?,
      failedAttempts: fields[26] as int? ?? 0,
      customBackgroundColor: fields[27] as int?,
      customCardColor: fields[28] as int?,
      highContrastMode: fields[29] as bool? ?? false,
      colorBlindMode: fields[30] as int? ?? 0,
      reduceMotion: fields[31] as bool? ?? false,
      simplifiedLayout: fields[32] as bool? ?? false,
      enlargedTouchTarget: fields[33] as bool? ?? false,
      followSystemAccessibility: fields[34] as bool? ?? false,
      userFontScale: fields[35] as double? ?? 1.0,
      semanticLabelsEnabled: fields[36] as bool? ?? true,
      backgroundScheme: fields[37] as String?,
      cardScheme: fields[38] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppConfig obj) {
    writer
      ..writeByte(39)
      ..writeByte(0)
      ..write(obj.themeType)
      ..writeByte(1)
      ..write(obj.autoTheme)
      ..writeByte(2)
      ..write(obj.fontScale)
      ..writeByte(3)
      ..write(obj.elderMode)
      ..writeByte(4)
      ..write(obj.language)
      ..writeByte(5)
      ..write(obj.isFirstLaunch)
      ..writeByte(6)
      ..write(obj.lastSyncAt)
      ..writeByte(7)
      ..write(obj.brightnessMode)
      ..writeByte(8)
      ..write(obj.defaultHomePage)
      ..writeByte(9)
      ..write(obj.timeFormat)
      ..writeByte(10)
      ..write(obj.hypertensionThreshold)
      ..writeByte(11)
      ..write(obj.hypotensionThreshold)
      ..writeByte(12)
      ..write(obj.heartRateMin)
      ..writeByte(13)
      ..write(obj.heartRateMax)
      ..writeByte(14)
      ..write(obj.abnormalSensitivity)
      ..writeByte(15)
      ..write(obj.showMedicalExplanation)
      ..writeByte(16)
      ..write(obj.reminderVibrate)
      ..writeByte(17)
      ..write(obj.reminderAdvanceMinutes)
      ..writeByte(18)
      ..write(obj.defaultReminderTime)
      ..writeByte(19)
      ..write(obj.appLockEnabled)
      ..writeByte(20)
      ..write(obj.appLockPassword)
      ..writeByte(21)
      ..write(obj.sensitiveDataBlurEnabled)
      ..writeByte(22)
      ..write(obj.autoLockTime)
      ..writeByte(23)
      ..write(obj.hashedPassword)
      ..writeByte(24)
      ..write(obj.salt)
      ..writeByte(25)
      ..write(obj.lockedUntil)
      ..writeByte(26)
      ..write(obj.failedAttempts)
      ..writeByte(27)
      ..write(obj.customBackgroundColor)
      ..writeByte(28)
      ..write(obj.customCardColor)
      ..writeByte(29)
      ..write(obj.highContrastMode)
      ..writeByte(30)
      ..write(obj.colorBlindMode)
      ..writeByte(31)
      ..write(obj.reduceMotion)
      ..writeByte(32)
      ..write(obj.simplifiedLayout)
      ..writeByte(33)
      ..write(obj.enlargedTouchTarget)
      ..writeByte(34)
      ..write(obj.followSystemAccessibility)
      ..writeByte(35)
      ..write(obj.userFontScale)
      ..writeByte(36)
      ..write(obj.semanticLabelsEnabled)
      ..writeByte(37)
      ..write(obj.backgroundScheme)
      ..writeByte(38)
      ..write(obj.cardScheme);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// EmergencyContact适配器
class EmergencyContactAdapter extends TypeAdapter<EmergencyContact> {
  @override
  final int typeId = 6;

  @override
  EmergencyContact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return EmergencyContact(
      id: fields[0] as String,
      name: fields[1] as String? ?? '',
      relationship: fields[2] as String? ?? '',
      phone: fields[3] as String? ?? '',
      isPrimary: fields[4] as bool? ?? false,
      note: fields[5] as String?,
      createdAt: fields[6] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, EmergencyContact obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.relationship)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.isPrimary)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// EmergencyCard适配器
class EmergencyCardAdapter extends TypeAdapter<EmergencyCard> {
  @override
  final int typeId = 7;

  @override
  EmergencyCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return EmergencyCard(
      id: fields[0] as String? ?? 'emergency_card_main',
      bloodType: fields[1] as int? ?? 0,
      allergies: fields[2] as String? ?? '',
      organDonor: fields[3] as int? ?? 0,
      preferredLanguage: fields[4] as String? ?? '普通话',
      medicalNotes: fields[5] as String? ?? '',
      updatedAt: fields[6] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, EmergencyCard obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bloodType)
      ..writeByte(2)
      ..write(obj.allergies)
      ..writeByte(3)
      ..write(obj.organDonor)
      ..writeByte(4)
      ..write(obj.preferredLanguage)
      ..writeByte(5)
      ..write(obj.medicalNotes)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
