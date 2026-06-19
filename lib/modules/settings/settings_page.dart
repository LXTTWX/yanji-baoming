import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yanji/core/constants/app_constants.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/core/providers/app_lock_provider.dart';
import 'package:yanji/core/providers/theme_provider.dart';
import 'package:yanji/core/theme/app_theme.dart';
import 'package:yanji/core/utils/demo_data.dart';
import 'package:yanji/core/utils/platform_file.dart';
import 'package:yanji/data/models/app_config.dart';
import 'package:yanji/data/models/color_scheme_config.dart';
import 'package:yanji/data/models/family_member.dart';
import 'package:yanji/data/models/fitness_record.dart';
import 'package:yanji/data/models/health_record.dart';
import 'package:yanji/data/models/reminder.dart';
import 'package:yanji/data/repositories/app_config_repository.dart';
import 'package:yanji/data/repositories/family_member_repository.dart';
import 'package:yanji/data/repositories/fitness_record_repository.dart';
import 'package:yanji/data/repositories/health_record_repository.dart';
import 'package:yanji/data/repositories/reminder_repository.dart';
import 'package:yanji/data/repositories/user_profile_repository.dart';
import 'package:yanji/modules/settings/lock_page.dart';
import 'package:yanji/modules/settings/settings_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:yanji/widgets/color_scheme_editor.dart';

/// 设置页面
///
/// 设计意图：用户在此调整 App 行为。按功能分组（外观/提醒/数据/关于），
/// 用 ExpansionTile 折叠，避免一屏堆满选项。长辈模式下字号与间距自动放大。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  final AppConfigRepository _configRepo = AppConfigRepository();
  final ReminderRepository _reminderRepo = ReminderRepository();

  bool _isLoading = true;
  List<Reminder> _reminders = [];
  /// 当前应用配置（持久化）
  AppConfig? _config;
  /// 亮度是否跟随系统（会话级状态，重启后默认关闭）
  bool _followSystem = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 系统亮度变化时，若跟随系统则同步
  @override
  void didChangePlatformBrightness() {
    if (_followSystem) {
      _applySystemBrightness();
    }
  }

  /// 加载配置与提醒数据
  Future<void> _loadData() async {
    final config = await _configRepo.getConfig();
    final reminders = await _reminderRepo.getAllReminders();
    setState(() {
      _config = config;
      _reminders = reminders;
      _isLoading = false;
    });
  }

  // ==================== 主题与显示 ====================

  /// 切换长辈模式
  Future<void> _toggleElderMode(bool value) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.toggleElderMode();
    setState(() {});
  }

  /// 切换亮度模式
  Future<void> _setBrightnessMode(AppBrightnessMode mode) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setBrightnessMode(mode);
    setState(() {});
  }

  /// 设置自定义背景色（null表示恢复默认）
  Future<void> _setCustomBackgroundColor(Color? color) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setCustomBackgroundColor(color);
    setState(() {});
  }

  /// 设置自定义卡片色（null表示恢复默认）
  Future<void> _setCustomCardColor(Color? color) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setCustomCardColor(color);
    setState(() {});
  }

  /// 打开背景颜色方案编辑器
  Future<void> _editBackgroundScheme() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final current = themeProvider.bgScheme ?? const ColorSchemeConfig();
    final result = await showDialog<ColorSchemeConfig?>(
      context: context,
      builder: (_) => ColorSchemeEditorDialog(
        title: '背景颜色',
        initialScheme: current,
        isBackground: true,
      ),
    );
    if (result != null) {
      await themeProvider.setBackgroundScheme(result);
      setState(() {});
    } else if (result == null) {
      // 用户点击"恢复默认"
      // 判断是否真的点了恢复默认（通过其他方式判断）
    }
  }

  /// 打开卡片颜色方案编辑器
  Future<void> _editCardScheme() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final current = themeProvider.cardScheme ?? const ColorSchemeConfig();
    final result = await showDialog<ColorSchemeConfig?>(
      context: context,
      builder: (_) => ColorSchemeEditorDialog(
        title: '卡片颜色',
        initialScheme: current,
        isBackground: false,
      ),
    );
    if (result != null) {
      await themeProvider.setCardScheme(result);
      setState(() {});
    }
  }

  /// 切换"跟随系统"亮度
  Future<void> _setFollowSystem(bool value) async {
    setState(() => _followSystem = value);
    if (value) {
      _applySystemBrightness();
    }
  }

  /// 根据系统当前亮度应用主题
  void _applySystemBrightness() {
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    _setBrightnessMode(isDark ? AppBrightnessMode.dark : AppBrightnessMode.light);
  }

  /// 更新首页默认启动页
  Future<void> _setDefaultHomePage(int page) async {
    await _configRepo.updateDefaultHomePage(page);
    setState(() {});
  }

  /// 更新时间格式
  Future<void> _setTimeFormat(int format) async {
    await _configRepo.updateTimeFormat(format);
    setState(() {});
  }

  // ==================== 健康参数设置 ====================

  /// 更新高血压阈值
  Future<void> _setHypertensionThreshold(int value) async {
    await _configRepo.updateHypertensionThreshold(value);
    setState(() {});
  }

  /// 更新低血压阈值
  Future<void> _setHypotensionThreshold(int value) async {
    await _configRepo.updateHypotensionThreshold(value);
    setState(() {});
  }

  /// 更新心率下限
  Future<void> _setHeartRateMin(int value) async {
    await _configRepo.updateHeartRateMin(value);
    setState(() {});
  }

  /// 更新心率上限
  Future<void> _setHeartRateMax(int value) async {
    await _configRepo.updateHeartRateMax(value);
    setState(() {});
  }

  /// 更新异常敏感度
  Future<void> _setSensitivity(int value) async {
    await _configRepo.updateAbnormalSensitivity(value);
    setState(() {});
  }

  /// 更新是否显示医学解释
  Future<void> _setShowMedicalExplanation(bool value) async {
    await _configRepo.updateShowMedicalExplanation(value);
    setState(() {});
  }

  // ==================== 提醒增强设置 ====================

  /// 更新提醒震动
  Future<void> _setReminderVibrate(bool value) async {
    await _configRepo.updateReminderVibrate(value);
    setState(() {});
  }

  /// 更新提前提醒分钟数
  Future<void> _setReminderAdvance(int index) async {
    final minutes = SettingsConstants.advanceMinutes[index];
    await _configRepo.updateReminderAdvanceMinutes(minutes);
    setState(() {});
  }

  // ==================== 提醒管理 ====================

  /// 某类型提醒是否全部启用
  bool _isReminderTypeEnabled(String type) {
    final list = _reminders.where((r) => r.type == type).toList();
    if (list.isEmpty) return false;
    return list.every((r) => r.enabled);
  }

  /// 切换某类型所有提醒的启用状态
  Future<void> _toggleReminderType(String type, bool value) async {
    final list = _reminders.where((r) => r.type == type).toList();
    if (list.isEmpty) {
      _showSnackBar('暂无$type提醒，请先在提醒页添加', isError: true);
      return;
    }
    for (final r in list) {
      r.enabled = value;
      await _reminderRepo.updateReminder(r);
    }
    setState(() {});
    _showSnackBar(value ? '已开启$type提醒' : '已关闭$type提醒');
  }

  /// 设置提醒默认时间（批量更新所有提醒时间）
  Future<void> _setReminderDefaultTime() async {
    if (_reminders.isEmpty) {
      _showSnackBar('暂无提醒可设置', isError: true);
      return;
    }

    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      helpText: '选择提醒默认时间',
    );
    if (picked == null) return;

    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    for (final r in _reminders) {
      r.time = timeStr;
      await _reminderRepo.updateReminder(r);
    }
    setState(() {});
    _showSnackBar('已将所有提醒时间设为 $timeStr');
  }

  // ==================== 数据管理 ====================

  /// 导出全部数据为加密JSON
  Future<void> _exportData() async {
    if (kIsWeb) {
      _showSnackBar('Web端暂不支持文件导出', isError: true);
      return;
    }

    try {
      _showSnackBar('正在导出数据...');

      final userProfileRepo = UserProfileRepository();
      final fitnessRepo = FitnessRecordRepository();
      final familyRepo = FamilyMemberRepository();
      final healthRepo = HealthRecordRepository();
      final reminderRepo = ReminderRepository();

      final profile = await userProfileRepo.getProfile();
      final fitnessRecords = await fitnessRepo.getAllRecords();
      final familyMembers = await familyRepo.getAllMembers();
      final healthRecords = await healthRepo.getAllRecords();
      final reminders = await reminderRepo.getAllReminders();

      final data = {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': AppConstants.appVersion,
        'userProfile': profile != null ? _profileToMap(profile) : null,
        'fitnessRecords': fitnessRecords.map(_fitnessToMap).toList(),
        'familyMembers': familyMembers.map(_familyToMap).toList(),
        'healthRecords': healthRecords.map(_healthToMap).toList(),
        'reminders': reminders.map(_reminderToMap).toList(),
      };

      final jsonString = jsonEncode(data);
      final encrypted = _encryptData(jsonString);

      final now = DateTime.now();
      final dateStr =
          '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}';
      final fileName = '${SettingsConstants.exportFilePrefix}_$dateStr.enc';

      final path = await exportToTempFile(encrypted, fileName);
      if (path != null) {
        _showSnackBar('已导出到: $path');
      } else {
        _showSnackBar('导出失败', isError: true);
      }
    } catch (e) {
      _showSnackBar('导出失败: $e', isError: true);
    }
  }

  /// 导入数据
  Future<void> _importData() async {
    if (kIsWeb) {
      _showSnackBar('Web端暂不支持文件导入', isError: true);
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['enc', 'json'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) {
        _showSnackBar('无法读取文件路径', isError: true);
        return;
      }

      final content = await readFileContent(filePath);
      if (content == null) {
        _showSnackBar('无法读取文件', isError: true);
        return;
      }

      String jsonString;
      if (filePath.endsWith('.enc')) {
        jsonString = _decryptData(content);
      } else {
        jsonString = content;
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('确认导入'),
          content: Text(
            '将导入以下数据：\n'
            '- 健身记录 ${(data['fitnessRecords'] as List?)?.length ?? 0} 条\n'
            '- 家庭成员 ${(data['familyMembers'] as List?)?.length ?? 0} 人\n'
            '- 健康记录 ${(data['healthRecords'] as List?)?.length ?? 0} 条\n'
            '- 提醒 ${(data['reminders'] as List?)?.length ?? 0} 条\n\n'
            '导入将合并到现有数据中。',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认导入'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await _performImport(data);
      _showSnackBar('导入成功');
    } catch (e) {
      _showSnackBar('导入失败，请检查文件格式', isError: true);
    }
  }

  /// 执行数据导入
  Future<void> _performImport(Map<String, dynamic> data) async {
    final fitnessRepo = FitnessRecordRepository();
    final familyRepo = FamilyMemberRepository();
    final healthRepo = HealthRecordRepository();
    final reminderRepo = ReminderRepository();

    for (final m in (data['familyMembers'] as List? ?? [])) {
      await familyRepo.addMember(_mapToFamily(m as Map<String, dynamic>));
    }
    for (final f in (data['fitnessRecords'] as List? ?? [])) {
      await fitnessRepo.addRecord(_mapToFitness(f as Map<String, dynamic>));
    }
    for (final h in (data['healthRecords'] as List? ?? [])) {
      await healthRepo.addRecord(_mapToHealth(h as Map<String, dynamic>));
    }
    for (final r in (data['reminders'] as List? ?? [])) {
      await reminderRepo.addReminder(_mapToReminder(r as Map<String, dynamic>));
    }
  }

  /// 清空所有数据（二次确认 + 红色警告）
  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error),
          SizedBox(width: 8),
          Text('确认清空'),
        ]),
        content: const Text(SettingsConstants.clearDataConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('清空', style: TextStyle(color: AppColors.textLight)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userProfileRepo = UserProfileRepository();
      final fitnessRepo = FitnessRecordRepository();
      final familyRepo = FamilyMemberRepository();
      final healthRepo = HealthRecordRepository();
      final reminderRepo = ReminderRepository();

      final profile = await userProfileRepo.getProfile();
      if (profile != null) {
        await userProfileRepo.deleteProfile(profile.id);
      }

      final fitnessRecords = await fitnessRepo.getAllRecords();
      for (final r in fitnessRecords) {
        await fitnessRepo.deleteRecord(r.id);
      }

      final members = await familyRepo.getAllMembers();
      for (final m in members) {
        await familyRepo.deleteMember(m.id);
      }

      final healthRecords = await healthRepo.getAllRecords();
      for (final r in healthRecords) {
        await healthRepo.deleteRecord(r.id);
      }

      final reminders = await reminderRepo.getAllReminders();
      for (final r in reminders) {
        await reminderRepo.deleteReminder(r.id);
      }

      _showSnackBar('数据已清空');
    } catch (e) {
      _showSnackBar('清空失败: $e', isError: true);
    }
  }

  /// 加载演示数据
  Future<void> _loadDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('加载演示数据'),
        content: const Text('将清空现有数据并加载完整的演示数据，包括：\n'
            '- 用户资料（身高175cm，体重70kg）\n'
            '- 14天健身打卡记录\n'
            '- 3位家庭成员（爸爸/妈妈/爷爷）\n'
            '- 30天血压心率记录\n'
            '- 4个提醒\n\n'
            '确定要继续吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('加载'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      _showSnackBar('正在加载演示数据...');
      await DemoData().loadAll();
      if (mounted) {
        _showSnackBar('演示数据已加载');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showSnackBar('加载失败: $e', isError: true);
    }
  }

  // ==================== 加密与序列化 ====================

  /// AES加密
  String _encryptData(String plainText) {
    final key = encrypt.Key.fromUtf8('yanji2024yanji2024yanji2024yanji!');
    final iv = encrypt.IV.fromUtf8('yanji2024yanji24');
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    return encrypter.encrypt(plainText, iv: iv).base64;
  }

  /// AES解密
  String _decryptData(String encryptedText) {
    final key = encrypt.Key.fromUtf8('yanji2024yanji2024yanji2024yanji!');
    final iv = encrypt.IV.fromUtf8('yanji2024yanji24');
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    return encrypter.decrypt64(encryptedText, iv: iv);
  }

  /// 数字补零
  String _pad(int n) => n.toString().padLeft(2, '0');

  Map<String, dynamic> _profileToMap(dynamic p) => {
        'id': p.id,
        'nickname': p.nickname,
        'height': p.height,
        'weight': p.weight,
        'age': p.age,
        'gender': p.gender,
        'createdAt': p.createdAt,
        'updatedAt': p.updatedAt,
      };

  Map<String, dynamic> _fitnessToMap(FitnessRecord r) => {
        'id': r.id,
        'planType': r.planType,
        'duration': r.duration,
        'calories': r.calories,
        'date': r.date,
        'completed': r.completed,
        'note': r.note,
        'createdAt': r.createdAt,
      };

  Map<String, dynamic> _familyToMap(FamilyMember m) => {
        'id': m.id,
        'name': m.name,
        'relationship': m.relationship,
        'age': m.age,
        'gender': m.gender,
        'phone': m.phone,
        'note': m.note,
        'createdAt': m.createdAt,
      };

  Map<String, dynamic> _healthToMap(HealthRecord r) => {
        'id': r.id,
        'memberId': r.memberId,
        'type': r.type,
        'value': r.value,
        'unit': r.unit,
        'isAbnormal': r.isAbnormal,
        'abnormalDesc': r.abnormalDesc,
        'measuredAt': r.measuredAt,
        'createdAt': r.createdAt,
      };

  Map<String, dynamic> _reminderToMap(Reminder r) => {
        'id': r.id,
        'type': r.type,
        'title': r.title,
        'content': r.content,
        'time': r.time,
        'repeatRule': r.repeatRule,
        'enabled': r.enabled,
        'memberId': r.memberId,
        'createdAt': r.createdAt,
      };

  FamilyMember _mapToFamily(Map<String, dynamic> m) {
    return FamilyMember(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      relationship: m['relationship'] as String? ?? '',
      age: m['age'] as int?,
      gender: m['gender'] as int? ?? 0,
      phone: m['phone'] as String?,
      note: m['note'] as String?,
      createdAt:
          m['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  FitnessRecord _mapToFitness(Map<String, dynamic> f) {
    return FitnessRecord(
      id: f['id'] as String? ?? '',
      planType: f['planType'] as String? ?? '',
      duration: f['duration'] as int? ?? 0,
      calories: (f['calories'] as num?)?.toDouble() ?? 0,
      date: f['date'] as String? ?? '',
      completed: f['completed'] as bool? ?? false,
      note: f['note'] as String?,
      createdAt:
          f['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  HealthRecord _mapToHealth(Map<String, dynamic> h) {
    return HealthRecord(
      id: h['id'] as String? ?? '',
      memberId: h['memberId'] as String? ?? '',
      type: h['type'] as String? ?? '',
      value: h['value'] as String? ?? '',
      unit: h['unit'] as String? ?? '',
      isAbnormal: h['isAbnormal'] as bool? ?? false,
      abnormalDesc: h['abnormalDesc'] as String?,
      measuredAt:
          h['measuredAt'] as String? ?? DateTime.now().toIso8601String(),
      createdAt:
          h['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Reminder _mapToReminder(Map<String, dynamic> r) {
    return Reminder(
      id: r['id'] as String? ?? '',
      type: r['type'] as String? ?? '',
      title: r['title'] as String? ?? '',
      content: r['content'] as String? ?? '',
      time: r['time'] as String? ?? '08:00',
      repeatRule: r['repeatRule'] as String? ?? '每天',
      enabled: r['enabled'] as bool? ?? true,
      memberId: r['memberId'] as String?,
      createdAt:
          r['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// 显示提示
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  // ==================== UI 构建 ====================

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final sw = MediaQuery.of(context).size.width;
    final padding = sw * 0.045;
    final fontSize = MediaQuery.of(context).textScaler.scale(14);
    final isElder = themeProvider.elderMode;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('设置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            padding, padding * 0.5, padding, padding * 2),
        children: [
          _buildAppearanceSection(theme, themeProvider, padding, fontSize, isElder),
          SizedBox(height: padding * 0.5),
          _buildAccessibilitySection(theme, themeProvider, padding, fontSize, isElder),
          SizedBox(height: padding * 0.5),
          _buildHealthSection(theme, padding, fontSize, isElder),
          SizedBox(height: padding * 0.5),
          _buildEmergencySection(theme, padding, fontSize, isElder),
          SizedBox(height: padding * 0.5),
          _buildSecuritySection(theme, padding, fontSize, isElder),
          SizedBox(height: padding * 0.5),
          _buildReminderSection(theme, padding, fontSize, isElder),
          SizedBox(height: padding * 0.5),
          _buildDataSection(theme, padding, fontSize, isElder),
          SizedBox(height: padding * 0.5),
          _buildAboutSection(theme, padding, fontSize),
        ],
      ),
    );
  }

  /// 第一组：外观与显示（默认展开）
  Widget _buildAppearanceSection(ThemeData theme, ThemeProvider tp,
      double padding, double fontSize, bool isElder) {
    return _buildSectionCard(
      theme: theme,
      padding: padding,
      icon: Icons.palette_outlined,
      iconColor: theme.colorScheme.primary,
      title: '外观与显示',
      subtitle: '深浅模式、自定义颜色、长辈模式',
      initiallyExpanded: true,
      children: [
        _buildBrightnessSelector(theme, tp, padding, fontSize),
        _buildDivider(theme, padding),
        _buildColorSchemeTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.format_color_fill_outlined,
          iconColor: AppColors.primary,
          title: '背景颜色',
          scheme: tp.bgScheme,
          fallbackColor: tp.customBgColor,
          isBackground: true,
          onPresetSelected: (color) => _setCustomBackgroundColor(color),
          onCustomEdit: _editBackgroundScheme,
          onReset: () => _setCustomBackgroundColor(null),
        ),
        _buildDivider(theme, padding),
        _buildColorSchemeTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.credit_card_outlined,
          iconColor: AppColors.accent,
          title: '卡片颜色',
          scheme: tp.cardScheme,
          fallbackColor: tp.customCardColor,
          isBackground: false,
          onPresetSelected: (color) => _setCustomCardColor(color),
          onCustomEdit: _editCardScheme,
          onReset: () => _setCustomCardColor(null),
        ),
        _buildDivider(theme, padding),
        _buildSwitchTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          isElder: isElder,
          icon: Icons.elderly_outlined,
          iconColor: AppColors.accent,
          title: '长辈模式',
          subtitle: '大字体、大按钮、高对比度',
          value: tp.elderMode,
          onChanged: _toggleElderMode,
        ),
        _buildDivider(theme, padding),
        _buildSelectorTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.home_outlined,
          iconColor: theme.colorScheme.primary,
          title: '首页默认启动页',
          subtitle: '打开 App 时首先显示的页面',
          options: SettingsConstants.homePageOptions,
          selectedIndex: _config?.defaultHomePage ?? 0,
          onSelected: _setDefaultHomePage,
        ),
        _buildDivider(theme, padding),
        _buildSelectorTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.schedule_outlined,
          iconColor: theme.colorScheme.primary,
          title: '时间格式',
          subtitle: '24小时制或12小时制',
          options: SettingsConstants.timeFormatOptions,
          selectedIndex: _config?.timeFormat ?? 0,
          onSelected: _setTimeFormat,
        ),
      ],
    );
  }

  // ==================== 无障碍设置 ====================

  /// 无障碍分组：字体缩放、高对比度、色盲模式、触控放大、减少动画、简化布局、跟随系统、屏幕朗读
  ///
  /// 设计意图：把所有视觉与交互辅助能力集中在一处，方便视障/色盲/运动障碍用户快速找到。
  /// 默认折叠，避免对普通用户造成干扰；长辈模式下展开后字号与间距自动放大。
  Widget _buildAccessibilitySection(
      ThemeData theme, ThemeProvider tp, double padding, double fontSize, bool isElder) {
    return _buildSectionCard(
      theme: theme,
      padding: padding,
      icon: Icons.accessibility_new_outlined,
      iconColor: AppColors.accent,
      title: '无障碍',
      subtitle: '字体缩放、高对比度、色盲模式、触控放大',
      initiallyExpanded: false,
      children: [
        // 跟随系统无障碍设置（置顶，因为会影响下方所有项）
        _buildSwitchTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          isElder: isElder,
          icon: Icons.settings_accessibility_outlined,
          iconColor: theme.colorScheme.primary,
          title: '跟随系统无障碍设置',
          subtitle: '自动同步系统的字体、对比度、动画偏好',
          value: tp.followSystemAccessibility,
          onChanged: _setFollowSystemAccessibility,
        ),
        _buildDivider(theme, padding),
        // 字体缩放滑块（带快捷档位）
        _buildFontScaleSlider(theme, tp, padding, fontSize, isElder),
        _buildDivider(theme, padding),
        // 高对比度模式
        _buildSwitchTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          isElder: isElder,
          icon: Icons.contrast_outlined,
          iconColor: AppColors.error,
          title: '高对比度模式',
          subtitle: '纯黑白背景、加粗文字、移除半透明',
          value: tp.highContrast,
          onChanged: _setHighContrast,
        ),
        _buildDivider(theme, padding),
        // 色盲辅助模式
        _buildColorBlindSelector(theme, tp, padding, fontSize, isElder),
        _buildDivider(theme, padding),
        // 可点击区域放大
        _buildSwitchTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          isElder: isElder,
          icon: Icons.touch_app_outlined,
          iconColor: AppColors.info,
          title: '可点击区域放大',
          subtitle: isElder ? '所有按钮触控区≥60dp' : '所有按钮触控区≥52dp',
          value: tp.enlargedTouchTarget,
          onChanged: _setEnlargedTouchTarget,
        ),
        _buildDivider(theme, padding),
        // 减少动画
        _buildSwitchTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          isElder: isElder,
          icon: Icons.animation_outlined,
          iconColor: AppColors.success,
          title: '减少动画',
          subtitle: '页面切换与装饰动效降级为瞬切',
          value: tp.reduceMotion,
          onChanged: _setReduceMotion,
        ),
        _buildDivider(theme, padding),
        // 简化布局
        _buildSwitchTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          isElder: isElder,
          icon: Icons.view_compact_outlined,
          iconColor: AppColors.accent,
          title: '简化布局',
          subtitle: '移除阴影与圆角装饰，只保留核心内容',
          value: tp.simplifiedLayout,
          onChanged: _setSimplifiedLayout,
        ),
        _buildDivider(theme, padding),
        // 屏幕朗读详细描述
        _buildSwitchTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          isElder: isElder,
          icon: Icons.record_voice_over_outlined,
          iconColor: theme.colorScheme.primary,
          title: '屏幕朗读详细描述',
          subtitle: '为图标与按钮补充语音语义标签',
          value: tp.semanticLabelsEnabled,
          onChanged: _setSemanticLabelsEnabled,
        ),
      ],
    );
  }

  /// 字体缩放滑块（带快捷档位 + 实时预览）
  ///
  /// 设计：滑块上方显示当前倍率与预览文字，下方提供 5 个快捷档位按钮。
  /// 跟随系统模式下，滑块禁用并提示"由系统控制"。
  Widget _buildFontScaleSlider(
      ThemeData theme, ThemeProvider tp, double padding, double fontSize, bool isElder) {
    final isLocked = tp.followSystemAccessibility;
    final scale = tp.userFontScale;
    // 快捷档位：0.85 / 1.0 / 1.2 / 1.5 / 1.8
    const presets = <double>[0.85, 1.0, 1.2, 1.5, 1.8];
    const presetLabels = <String>['小', '标准', '大', '更大', '最大'];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding * 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(padding * 0.35),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.format_size_outlined,
                    color: AppColors.primary, size: fontSize * 1.2),
              ),
              SizedBox(width: padding * 0.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('字体缩放',
                        style: TextStyle(
                            fontSize: fontSize, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text(
                      isLocked
                          ? '当前由系统控制（${tp.fontScale.toStringAsFixed(2)}×）'
                          : '当前 ${scale.toStringAsFixed(2)}×，生效 ${tp.fontScale.toStringAsFixed(2)}×',
                      style: TextStyle(
                          fontSize: fontSize * 0.8,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // 当前倍率大数字
              Text('${(tp.fontScale * 100).round()}%',
                  style: TextStyle(
                      fontSize: fontSize * 1.4,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ],
          ),
          SizedBox(height: padding * 0.4),
          // 实时预览
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding * 0.5),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              '家檐安记：今日血压 118/76，心率 72，状态良好',
              style: TextStyle(
                fontSize: 14 * tp.fontScale,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: padding * 0.4),
          // 滑块
          Opacity(
            opacity: isLocked ? 0.4 : 1.0,
            child: AbsorbPointer(
              absorbing: isLocked,
              child: Slider(
                value: scale,
                min: 0.8,
                max: 1.8,
                divisions: 20,
                activeColor: AppColors.primary,
                label: '${(scale * 100).round()}%',
                onChanged: (v) => _setUserFontScale(v),
              ),
            ),
          ),
          SizedBox(height: padding * 0.2),
          // 快捷档位按钮
          Opacity(
            opacity: isLocked ? 0.4 : 1.0,
            child: AbsorbPointer(
              absorbing: isLocked,
              child: Row(
                children: [
                  for (int i = 0; i < presets.length; i++) ...[
                    if (i > 0) SizedBox(width: padding * 0.3),
                    Expanded(
                      child: _buildFontScalePreset(
                        theme: theme,
                        padding: padding,
                        fontSize: fontSize,
                        label: presetLabels[i],
                        value: presets[i],
                        currentValue: scale,
                        onTap: () => _setUserFontScale(presets[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 字体缩放快捷档位按钮
  Widget _buildFontScalePreset({
    required ThemeData theme,
    required double padding,
    required double fontSize,
    required String label,
    required double value,
    required double currentValue,
    required VoidCallback onTap,
  }) {
    final isSelected = (currentValue - value).abs() < 0.01;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padding * 0.3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: fontSize * 0.85,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                )),
            SizedBox(height: 2),
            Text('${(value * 100).round()}%',
                style: TextStyle(
                  fontSize: fontSize * 0.7,
                  color: isSelected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }

  /// 色盲辅助模式选择器
  ///
  /// 提供 4 个选项卡片：关闭 / 红色盲 / 绿色盲 / 蓝黄色盲，
  /// 每个卡片用对应的色块预览，方便用户直观选择。
  Widget _buildColorBlindSelector(
      ThemeData theme, ThemeProvider tp, double padding, double fontSize, bool isElder) {
    final modes = <_ColorBlindOption>[
      _ColorBlindOption(
        mode: ColorBlindMode.off,
        label: '关闭',
        desc: '使用默认配色',
        previewColors: const [AppColors.error, AppColors.success, AppColors.info],
      ),
      _ColorBlindOption(
        mode: ColorBlindMode.protanopia,
        label: '红色盲',
        desc: '红绿改为蓝黄',
        previewColors: const [Color(0xFF0072B2), Color(0xFFF0E442), Color(0xFF56B4E9)],
      ),
      _ColorBlindOption(
        mode: ColorBlindMode.deuteranopia,
        label: '绿色盲',
        desc: '红绿改为蓝橙',
        previewColors: const [Color(0xFF0072B2), Color(0xFFE69F00), Color(0xFF56B4E9)],
      ),
      _ColorBlindOption(
        mode: ColorBlindMode.tritanopia,
        label: '蓝黄色盲',
        desc: '蓝黄改为红绿',
        previewColors: const [Color(0xFFD55E00), Color(0xFF009E73), Color(0xFFF0E442)],
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding * 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(padding * 0.35),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.palette_outlined,
                    color: AppColors.accent, size: fontSize * 1.2),
              ),
              SizedBox(width: padding * 0.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('色盲辅助模式',
                        style: TextStyle(
                            fontSize: fontSize, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('替换关键色，让色盲用户也能区分状态',
                        style: TextStyle(
                            fontSize: fontSize * 0.8,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: padding * 0.4),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: padding * 0.3,
            crossAxisSpacing: padding * 0.3,
            childAspectRatio: 2.4,
            children: modes.map((m) {
              final isSelected = tp.colorBlindMode == m.mode;
              return InkWell(
                onTap: () => _setColorBlindMode(m.mode),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.all(padding * 0.3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 色块预览
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: m.previewColors
                            .map((c) => Container(
                                  width: fontSize * 1.2,
                                  height: fontSize * 0.4,
                                  margin: EdgeInsets.only(bottom: 2),
                                  decoration: BoxDecoration(
                                    color: c,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ))
                            .toList(),
                      ),
                      SizedBox(width: padding * 0.3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(m.label,
                                style: TextStyle(
                                    fontSize: fontSize * 0.9,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.accent
                                        : theme.colorScheme.onSurface)),
                            SizedBox(height: 2),
                            Text(m.desc,
                                style: TextStyle(
                                    fontSize: fontSize * 0.7,
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle,
                            color: AppColors.accent, size: fontSize * 1.1),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 设置高对比度模式
  Future<void> _setHighContrast(bool value) async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    await tp.setHighContrast(value);
    setState(() {});
  }

  /// 设置色盲辅助模式
  Future<void> _setColorBlindMode(ColorBlindMode mode) async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    await tp.setColorBlindMode(mode);
    setState(() {});
  }

  /// 设置减少动画
  Future<void> _setReduceMotion(bool value) async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    await tp.setReduceMotion(value);
    setState(() {});
  }

  /// 设置简化布局
  Future<void> _setSimplifiedLayout(bool value) async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    await tp.setSimplifiedLayout(value);
    setState(() {});
  }

  /// 设置可点击区域放大
  Future<void> _setEnlargedTouchTarget(bool value) async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    await tp.setEnlargedTouchTarget(value);
    setState(() {});
  }

  /// 设置跟随系统无障碍
  Future<void> _setFollowSystemAccessibility(bool value) async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    await tp.setFollowSystemAccessibility(value);
    setState(() {});
  }

  /// 设置用户自定义字体缩放
  Future<void> _setUserFontScale(double value) async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    await tp.setUserFontScale(value);
    setState(() {});
  }

  /// 设置屏幕朗读详细描述
  Future<void> _setSemanticLabelsEnabled(bool value) async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    await tp.setSemanticLabelsEnabled(value);
    setState(() {});
  }

  /// 淂浅模式选择器（跟随系统 / 亮色 / 暗色）
  Widget _buildBrightnessSelector(
      ThemeData theme, ThemeProvider tp, double padding, double fontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding * 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding * 0.2),
            child: Text('深浅模式',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          SizedBox(height: padding * 0.4),
          Row(
            children: [
              Expanded(
                child: _buildBrightnessOption(
                  theme, padding, fontSize,
                  icon: Icons.brightness_auto_outlined,
                  label: '跟随系统',
                  isSelected: _followSystem,
                  onTap: () => _setFollowSystem(true),
                  accentColor: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: padding * 0.4),
              Expanded(
                child: _buildBrightnessOption(
                  theme, padding, fontSize,
                  icon: Icons.light_mode_outlined,
                  label: '亮色',
                  isSelected: !_followSystem &&
                      tp.brightnessMode == AppBrightnessMode.light,
                  onTap: () => _setFollowSystem(false)
                      .then((_) => _setBrightnessMode(AppBrightnessMode.light)),
                  accentColor: const Color(0xFFF59E0B),
                ),
              ),
              SizedBox(width: padding * 0.4),
              Expanded(
                child: _buildBrightnessOption(
                  theme, padding, fontSize,
                  icon: Icons.dark_mode_outlined,
                  label: '暗色',
                  isSelected: !_followSystem &&
                      tp.brightnessMode == AppBrightnessMode.dark,
                  onTap: () => _setFollowSystem(false)
                      .then((_) => _setBrightnessMode(AppBrightnessMode.dark)),
                  accentColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 单个亮度选项
  Widget _buildBrightnessOption(ThemeData theme, double padding, double fontSize,
      {required IconData icon,
      required String label,
      required bool isSelected,
      required VoidCallback onTap,
      required Color accentColor}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: padding * 0.5),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: fontSize * 1.4,
                color: isSelected ? accentColor : theme.colorScheme.onSurfaceVariant),
            SizedBox(height: padding * 0.2),
            Text(label,
                style: TextStyle(
                  fontSize: fontSize * 0.85,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? accentColor : theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }

  /// 隐私与安全分组：启动锁、敏感数据模糊、自动锁定
  Widget _buildSecuritySection(
      ThemeData theme, double padding, double fontSize, bool isElder) {
    final config = _config;
    final lockEnabled = config?.appLockEnabled ?? false;
    final blurEnabled = config?.sensitiveDataBlurEnabled ?? false;
    final autoLockSec = config?.autoLockTime ?? 0;
    final autoLockIndex =
        SettingsConstants.autoLockSeconds.indexOf(autoLockSec).clamp(0, 3);

    return _buildSectionCard(
      theme: theme,
      padding: padding,
      icon: Icons.shield_outlined,
      iconColor: AppColors.primary,
      title: '隐私与安全',
      subtitle: '应用锁、敏感数据保护、自动锁定',
      initiallyExpanded: false,
      children: [
        // 应用启动锁开关
        _buildSwitchTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          isElder: isElder,
          icon: Icons.lock_outline,
          iconColor: AppColors.primary,
          title: '应用启动锁',
          subtitle: '启动应用时需要输入4位数字密码',
          value: lockEnabled,
          onChanged: (v) => _onAppLockToggle(v),
        ),
        _buildDivider(theme, padding),
        // 修改密码（仅启动锁开启时显示）
        if (lockEnabled) ...[
          _buildActionTile(
            theme: theme,
            padding: padding,
            fontSize: fontSize,
            icon: Icons.edit_outlined,
            iconColor: AppColors.primary,
            title: '修改密码',
            subtitle: '验证原密码后设置新密码',
            onTap: _onChangePassword,
          ),
          _buildDivider(theme, padding),
          // 自动锁定时间
          _buildSelectorTile(
            theme: theme,
            padding: padding,
            fontSize: fontSize,
            icon: Icons.timer_outlined,
            iconColor: AppColors.primary,
            title: '自动锁定时间',
            subtitle: '后台停留超时后自动锁定',
            options: SettingsConstants.autoLockOptions,
            selectedIndex: autoLockIndex,
            onSelected: _setAutoLockTime,
          ),
          _buildDivider(theme, padding),
        ],
        // 敏感数据模糊显示
        _buildSwitchTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          isElder: isElder,
          icon: Icons.visibility_off_outlined,
          iconColor: AppColors.primary,
          title: '敏感数据模糊显示',
          subtitle: '血压、心率、体重默认模糊，按住查看',
          value: blurEnabled,
          onChanged: _setSensitiveBlur,
        ),
      ],
    );
  }

  /// 急救卡入口分组
  Widget _buildEmergencySection(
      ThemeData theme, double padding, double fontSize, bool isElder) {
    return _buildSectionCard(
      theme: theme,
      padding: padding,
      icon: Icons.emergency,
      iconColor: AppColors.error,
      title: '医疗急救卡',
      subtitle: '血型、过敏史、紧急联系人，紧急时可救命',
      initiallyExpanded: false,
      children: [
        _buildActionTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.health_and_safety_outlined,
          iconColor: AppColors.error,
          title: '查看 / 编辑急救卡',
          subtitle: '管理血型、过敏史、紧急联系人等救命信息',
          onTap: () => context.push('/profile/settings/emergency'),
        ),
        _buildDivider(theme, padding),
        _buildActionTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.lock_open_outlined,
          iconColor: AppColors.warning,
          title: '锁屏快速查看',
          subtitle: '不解锁即可查看关键急救信息',
          onTap: () => context.push('/emergency/lock'),
        ),
      ],
    );
  }

  /// 应用启动锁开关切换
  Future<void> _onAppLockToggle(bool enable) async {
    if (enable) {
      // 开启：进入密码设置流程
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LockPage(
            mode: LockMode.setup,
            onPasswordSet: () {
              // 设置成功，刷新状态
              _loadData();
              if (mounted) Navigator.of(context).pop();
            },
            onCancel: () {
              if (mounted) Navigator.of(context).pop();
            },
          ),
          fullscreenDialog: true,
        ),
      );
    } else {
      // 关闭：验证当前密码
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LockPage(
            mode: LockMode.verify,
            onUnlocked: () async {
              // 验证通过，关闭启动锁并清除所有密码数据
              await _configRepo.disableAppLock();
              // 通知全局 Provider
              if (mounted) {
                context.read<AppLockProvider>().refreshConfig();
              }
              if (mounted) Navigator.of(context).pop();
            },
          ),
          fullscreenDialog: true,
        ),
      );
    }
    await _loadData();
    if (mounted) setState(() {});
  }

  /// 修改密码
  Future<void> _onChangePassword() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LockPage(
          mode: LockMode.change,
          onPasswordSet: () {
            if (mounted) Navigator.of(context).pop();
          },
          onCancel: () {
            if (mounted) Navigator.of(context).pop();
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  /// 设置敏感数据模糊
  Future<void> _setSensitiveBlur(bool value) async {
    await _configRepo.updateSensitiveDataBlurEnabled(value);
    await _loadData();
    if (mounted) setState(() {});
  }

  /// 设置自动锁定时间
  Future<void> _setAutoLockTime(int index) async {
    final seconds = SettingsConstants.autoLockSeconds[index];
    await _configRepo.updateAutoLockTime(seconds);
    await _loadData();
    if (mounted) setState(() {});
  }

  /// 第二组：健康参数设置（核心特色）
  Widget _buildHealthSection(
      ThemeData theme, double padding, double fontSize, bool isElder) {
    final config = _config;
    return _buildSectionCard(
      theme: theme,
      padding: padding,
      icon: Icons.monitor_heart_outlined,
      iconColor: AppColors.error,
      title: '健康参数设置',
      subtitle: '血压心率阈值、异常判定标准',
      initiallyExpanded: false,
      children: [
        _buildNumberTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.arrow_upward_rounded,
          iconColor: AppColors.error,
          title: '高血压阈值（收缩压）',
          subtitle: '超过此值判定为高血压',
          unit: 'mmHg',
          value: config?.hypertensionThreshold ?? 140,
          min: 120,
          max: 180,
          step: 1,
          onChanged: _setHypertensionThreshold,
        ),
        _buildDivider(theme, padding),
        _buildNumberTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.arrow_downward_rounded,
          iconColor: AppColors.info,
          title: '低血压阈值（收缩压）',
          subtitle: '低于此值判定为低血压',
          unit: 'mmHg',
          value: config?.hypotensionThreshold ?? 90,
          min: 60,
          max: 100,
          step: 1,
          onChanged: _setHypotensionThreshold,
        ),
        _buildDivider(theme, padding),
        _buildNumberTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.south_rounded,
          iconColor: AppColors.success,
          title: '心率下限',
          subtitle: '低于此值判定为心率过缓',
          unit: '次/分',
          value: config?.heartRateMin ?? 60,
          min: 40,
          max: 80,
          step: 1,
          onChanged: _setHeartRateMin,
        ),
        _buildDivider(theme, padding),
        _buildNumberTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.north_rounded,
          iconColor: AppColors.warning,
          title: '心率上限',
          subtitle: '超过此值判定为心率过速',
          unit: '次/分',
          value: config?.heartRateMax ?? 100,
          min: 80,
          max: 160,
          step: 1,
          onChanged: _setHeartRateMax,
        ),
        _buildDivider(theme, padding),
        _buildSelectorTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.tune_outlined,
          iconColor: theme.colorScheme.primary,
          title: '异常提醒敏感度',
          subtitle: SettingsConstants
              .sensitivityDescriptions[config?.abnormalSensitivity ?? 1],
          options: SettingsConstants.sensitivityOptions,
          selectedIndex: config?.abnormalSensitivity ?? 1,
          onSelected: _setSensitivity,
        ),
        _buildDivider(theme, padding),
        _buildSwitchTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          isElder: isElder,
          icon: Icons.menu_book_outlined,
          iconColor: AppColors.accent,
          title: '显示医学解释',
          subtitle: '异常时显示通俗中文说明',
          value: config?.showMedicalExplanation ?? true,
          onChanged: _setShowMedicalExplanation,
        ),
      ],
    );
  }

  /// 第二组：提醒与通知
  Widget _buildReminderSection(
      ThemeData theme, double padding, double fontSize, bool isElder) {
    final types = [
      ('健身', Icons.fitness_center, AppColors.primary),
      ('服药', Icons.medication_outlined, AppColors.success),
      ('测压', Icons.favorite_outline, AppColors.error),
      ('喝水', Icons.water_drop_outlined, AppColors.info),
    ];

    return _buildSectionCard(
      theme: theme,
      padding: padding,
      icon: Icons.notifications_outlined,
      iconColor: AppColors.warning,
      title: '提醒与通知',
      subtitle: '管理各类提醒开关与默认时间',
      initiallyExpanded: false,
      children: [
        for (int i = 0; i < types.length; i++) ...[
          if (i > 0) _buildDivider(theme, padding),
          _buildSwitchTile(
            theme: theme,
            padding: padding,
            fontSize: fontSize,
            isElder: isElder,
            icon: types[i].$2,
            iconColor: types[i].$3,
            title: '${types[i].$1}提醒',
            subtitle: _reminderCountDesc(types[i].$1),
            value: _isReminderTypeEnabled(types[i].$1),
            onChanged: (v) => _toggleReminderType(types[i].$1, v),
          ),
        ],
        _buildDivider(theme, padding),
        _buildActionTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.access_time_outlined,
          iconColor: theme.colorScheme.primary,
          title: '提醒默认时间设置',
          subtitle: '批量设置所有提醒时间',
          onTap: _setReminderDefaultTime,
        ),
        _buildDivider(theme, padding),
        _buildSwitchTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          isElder: isElder,
          icon: Icons.vibration_outlined,
          iconColor: AppColors.accent,
          title: '提醒震动',
          subtitle: '提醒触发时设备震动',
          value: _config?.reminderVibrate ?? true,
          onChanged: _setReminderVibrate,
        ),
        _buildDivider(theme, padding),
        _buildSelectorTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.snooze_outlined,
          iconColor: AppColors.info,
          title: '提前提醒',
          subtitle: '在设定时间前提前通知',
          options: SettingsConstants.advanceOptions,
          selectedIndex: SettingsConstants.advanceMinutes
              .indexOf(_config?.reminderAdvanceMinutes ?? 0)
              .clamp(0, SettingsConstants.advanceMinutes.length - 1),
          onSelected: _setReminderAdvance,
        ),
      ],
    );
  }

  /// 提醒数量描述
  String _reminderCountDesc(String type) {
    final count = _reminders.where((r) => r.type == type).length;
    if (count == 0) return '暂无提醒';
    return '共 $count 条提醒';
  }

  /// 第三组：数据管理
  Widget _buildDataSection(
      ThemeData theme, double padding, double fontSize, bool isElder) {
    return _buildSectionCard(
      theme: theme,
      padding: padding,
      icon: Icons.storage_outlined,
      iconColor: AppColors.success,
      title: '数据管理',
      subtitle: '导出、导入、清空与演示数据',
      initiallyExpanded: false,
      children: [
        _buildActionTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.upload_outlined,
          iconColor: theme.colorScheme.primary,
          title: '导出所有数据',
          subtitle: 'AES加密导出全部数据',
          onTap: _exportData,
        ),
        _buildDivider(theme, padding),
        _buildActionTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.download_outlined,
          iconColor: AppColors.success,
          title: '导入数据',
          subtitle: '从加密文件恢复数据',
          onTap: _importData,
        ),
        _buildDivider(theme, padding),
        _buildActionTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.auto_awesome_outlined,
          iconColor: AppColors.accent,
          title: '一键加载演示数据',
          subtitle: '清空现有数据并加载完整体验数据',
          onTap: _loadDemoData,
        ),
        _buildDivider(theme, padding),
        _buildDangerTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.delete_forever_outlined,
          title: '清空所有数据',
          subtitle: '删除本地所有健康和健身数据，不可恢复',
          onTap: _clearAllData,
        ),
      ],
    );
  }

  /// 第四组：关于与帮助
  Widget _buildAboutSection(ThemeData theme, double padding, double fontSize) {
    return _buildSectionCard(
      theme: theme,
      padding: padding,
      icon: Icons.info_outline,
      iconColor: theme.colorScheme.primary,
      title: '关于与帮助',
      subtitle: '应用信息、项目介绍、使用帮助',
      initiallyExpanded: false,
      children: [
        Padding(
          padding: EdgeInsets.all(padding * 0.6),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(padding * 0.6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_outlined,
                    color: theme.colorScheme.primary, size: fontSize * 1.8),
              ),
              SizedBox(width: padding * 0.6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppConstants.appName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('版本 ${AppConstants.appVersion}  ·  代号 ${AppConstants.appNameEn}',
                        style: TextStyle(
                            fontSize: fontSize * 0.85,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildDivider(theme, padding),
        _buildActionTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.description_outlined,
          iconColor: theme.colorScheme.onSurfaceVariant,
          title: '项目介绍',
          subtitle: SettingsConstants.appDescription,
          onTap: () => _showInfoDialog('项目介绍', SettingsConstants.appDescription),
        ),
        _buildDivider(theme, padding),
        _buildActionTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.help_outline,
          iconColor: theme.colorScheme.onSurfaceVariant,
          title: '使用帮助',
          subtitle: '快速上手指南',
          onTap: _showHelpDialog,
        ),
        _buildDivider(theme, padding),
        _buildActionTile(
          theme: theme,
          padding: padding,
          fontSize: fontSize,
          icon: Icons.security_outlined,
          iconColor: theme.colorScheme.onSurfaceVariant,
          title: '隐私说明',
          subtitle: SettingsConstants.privacyStatement,
          onTap: () =>
              _showInfoDialog('隐私说明', SettingsConstants.privacyStatement),
        ),
      ],
    );
  }

  /// 显示信息对话框
  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('知道了')),
        ],
      ),
    );
  }

  /// 显示使用帮助
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('使用帮助'),
        content: const SingleChildScrollView(
          child: Text(
            '【健身】选择入门计划，每日打卡，查看统计与成就。\n\n'
            '【守护】添加家庭成员，记录血压心率，异常自动标红。\n\n'
            '【提醒】设置健身/喝水/测压/服药提醒，本地通知。\n\n'
            '【设置】切换主题、长辈模式，管理数据导出导入。\n\n'
            '所有数据仅存储在本地，绝不上传。',
            style: TextStyle(height: 1.6),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('知道了')),
        ],
      ),
    );
  }

  // ==================== 通用组件 ====================

  /// 分组卡片容器（ExpansionTile 折叠式）
  Widget _buildSectionCard({
    required ThemeData theme,
    required double padding,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool initiallyExpanded,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.symmetric(
              horizontal: padding * 0.6, vertical: padding * 0.2),
          childrenPadding: EdgeInsets.fromLTRB(
              padding * 0.6, 0, padding * 0.6, padding * 0.6),
          leading: Container(
            padding: EdgeInsets.all(padding * 0.4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: padding * 0.7),
          ),
          title: Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(subtitle,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          iconColor: theme.colorScheme.onSurfaceVariant,
          collapsedIconColor: theme.colorScheme.onSurfaceVariant,
          children: children,
        ),
      ),
    );
  }

  /// 颜色方案选择行
  ///
  /// 显示当前颜色方案状态（默认/纯色/渐变），点击弹出选择面板：
  /// - 预设色板（快捷选择常用纯色）
  /// - 自定义调色盘（HSV色盘 + 渐变控制）
  Widget _buildColorSchemeTile({
    required ThemeData theme,
    required double padding,
    required double fontSize,
    required IconData icon,
    required Color iconColor,
    required String title,
    required ColorSchemeConfig? scheme,
    required Color? fallbackColor,
    required bool isBackground,
    required ValueChanged<Color> onPresetSelected,
    required VoidCallback onCustomEdit,
    required VoidCallback onReset,
  }) {
    // 计算副标题和预览色
    String subtitle;
    Color? previewColor;
    bool isGradient = false;
    if (scheme != null) {
      if (scheme.isGradient) {
        subtitle = '渐变';
        isGradient = true;
        previewColor = scheme.effectiveColor;
      } else {
        subtitle = '纯色';
        previewColor = scheme.solidColor;
      }
    } else if (fallbackColor != null) {
      subtitle = '纯色';
      previewColor = fallbackColor;
    } else {
      subtitle = '默认';
    }

    return InkWell(
      onTap: () => _showColorSchemePickerDialog(
        theme: theme,
        title: title,
        scheme: scheme,
        fallbackColor: fallbackColor,
        isBackground: isBackground,
        onPresetSelected: onPresetSelected,
        onCustomEdit: onCustomEdit,
        onReset: onReset,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: padding * 0.6, vertical: padding * 0.5),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: fontSize * 1.3),
            SizedBox(width: padding * 0.4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.w500)),
                  SizedBox(height: padding * 0.1),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: fontSize * 0.85,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            // 当前颜色预览
            if (isGradient && scheme != null)
              Container(
                width: fontSize * 1.6,
                height: fontSize * 1.6,
                decoration: BoxDecoration(
                  gradient: scheme.linearGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              )
            else
              Container(
                width: fontSize * 1.6,
                height: fontSize * 1.6,
                decoration: BoxDecoration(
                  color: previewColor ??
                      theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
            SizedBox(width: padding * 0.2),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: fontSize * 1.4),
          ],
        ),
      ),
    );
  }

  /// 显示颜色方案选择对话框
  ///
  /// 提供三个入口：预设色板、自定义调色盘、恢复默认。
  Future<void> _showColorSchemePickerDialog({
    required ThemeData theme,
    required String title,
    required ColorSchemeConfig? scheme,
    required Color? fallbackColor,
    required bool isBackground,
    required ValueChanged<Color> onPresetSelected,
    required VoidCallback onCustomEdit,
    required VoidCallback onReset,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final sw = MediaQuery.of(ctx).size.width;
        final padding = sw * 0.04;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.color_lens, color: theme.colorScheme.primary),
              SizedBox(width: padding * 0.4),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 预设色板
              Text('快捷预设色板',
                  style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant)),
              SizedBox(height: padding * 0.5),
              _buildPresetColorGrid(
                theme,
                padding,
                scheme,
                fallbackColor,
                onPresetSelected,
                ctx,
              ),
              SizedBox(height: padding * 0.6),
              Divider(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.3)),
              SizedBox(height: padding * 0.3),
              // 自定义调色盘入口
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(padding * 0.3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.palette_outlined,
                      color: theme.colorScheme.primary),
                ),
                title: const Text('自定义调色盘',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(isBackground ? '纯色 / 渐变 / 方向 / 强度' : '纯色 / 渐变 / 方向 / 强度',
                    style: TextStyle(fontSize: 12)),
                trailing: Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
                onTap: () {
                  Navigator.of(ctx).pop('custom');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('reset'),
              child: const Text('恢复默认'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );

    if (result == 'custom') {
      onCustomEdit();
    } else if (result == 'reset') {
      onReset();
    }
  }

  /// 预设色板网格
  Widget _buildPresetColorGrid(
    ThemeData theme,
    double padding,
    ColorSchemeConfig? scheme,
    Color? fallbackColor,
    ValueChanged<Color> onPresetSelected,
    BuildContext ctx,
  ) {
    const presets = <Color>[
      Color(0xFFFFFFFF), // 纯白
      Color(0xFFF5F5F5), // 浅灰
      Color(0xFFE3F2FD), // 淡蓝
      Color(0xFFE8F5E9), // 淡绿
      Color(0xFFF3E5F5), // 淡紫
      Color(0xFFFCE4EC), // 淡粉
      Color(0xFFFFF8E1), // 米黄
      Color(0xFFEFEBE9), // 浅棕
      Color(0xFF263238), // 深灰蓝
      Color(0xFF1E1E1E), // 深黑
    ];

    final currentColor = scheme?.effectiveColor ?? fallbackColor;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 5,
      mainAxisSpacing: padding * 0.4,
      crossAxisSpacing: padding * 0.4,
      childAspectRatio: 1,
      children: presets.map((color) {
        final selected =
            currentColor != null && currentColor.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () {
            Navigator.of(ctx).pop();
            onPresetSelected(color);
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: selected ? 3 : 1.5,
              ),
            ),
            child: selected
                ? Icon(Icons.check,
                    color: _isLightColor(color) ? Colors.black87 : Colors.white,
                    size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  /// 判断颜色是否为浅色（用于选择对话框中对勾颜色）
  bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  /// 开关行
  Widget _buildSwitchTile({
    required ThemeData theme,
    required double padding,
    required double fontSize,
    required bool isElder,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding * 0.3),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(padding * 0.35),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: fontSize * 1.2),
          ),
          SizedBox(width: padding * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: fontSize * 0.8,
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Transform.scale(
            scale: isElder ? 1.3 : 1.1,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  /// 操作行（点击触发）
  Widget _buildActionTile({
    required ThemeData theme,
    required double padding,
    required double fontSize,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padding * 0.4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(padding * 0.35),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: fontSize * 1.2),
            ),
            SizedBox(width: padding * 0.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: fontSize * 0.8,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  /// 危险操作行（红色警告样式）
  Widget _buildDangerTile({
    required ThemeData theme,
    required double padding,
    required double fontSize,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padding * 0.4),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(padding * 0.35),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.error, size: fontSize * 1.2),
            ),
            SizedBox(width: padding * 0.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error)),
                  SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: fontSize * 0.8,
                          color: AppColors.error.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.error.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  /// 下拉选择行（点击弹出选项底部弹窗）
  Widget _buildSelectorTile({
    required ThemeData theme,
    required double padding,
    required double fontSize,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    final safeIndex = selectedIndex.clamp(0, options.length - 1);
    return InkWell(
      onTap: () => _showOptionSheet(
        theme: theme,
        padding: padding,
        fontSize: fontSize,
        title: title,
        options: options,
        selectedIndex: safeIndex,
        onSelected: onSelected,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padding * 0.4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(padding * 0.35),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: fontSize * 1.2),
            ),
            SizedBox(width: padding * 0.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: fontSize * 0.8,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: padding * 0.35, vertical: padding * 0.15),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                options[safeIndex],
                style: TextStyle(
                    fontSize: fontSize * 0.85,
                    fontWeight: FontWeight.w600,
                    color: iconColor),
              ),
            ),
            SizedBox(width: padding * 0.2),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  /// 选项底部弹窗
  void _showOptionSheet({
    required ThemeData theme,
    required double padding,
    required double fontSize,
    required String title,
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(padding * 0.6),
              child: Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            for (int i = 0; i < options.length; i++)
              InkWell(
                onTap: () {
                  onSelected(i);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: padding * 0.8, vertical: padding * 0.5),
                  color: i == selectedIndex
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(options[i],
                            style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: i == selectedIndex
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: i == selectedIndex
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface)),
                      ),
                      if (i == selectedIndex)
                        Icon(Icons.check_circle,
                            color: theme.colorScheme.primary,
                            size: fontSize * 1.2),
                    ],
                  ),
                ),
              ),
            SizedBox(height: padding * 0.4),
          ],
        ),
      ),
    );
  }

  /// 数值调节行（带 - / + 按钮和滑块）
  Widget _buildNumberTile({
    required ThemeData theme,
    required double padding,
    required double fontSize,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String unit,
    required int value,
    required int min,
    required int max,
    required int step,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding * 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(padding * 0.35),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: fontSize * 1.2),
              ),
              SizedBox(width: padding * 0.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: fontSize, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: fontSize * 0.8,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              // 数值显示 + 单位
              Text('$value',
                  style: TextStyle(
                      fontSize: fontSize * 1.4,
                      fontWeight: FontWeight.bold,
                      color: iconColor)),
              SizedBox(width: 4),
              Text(unit,
                  style: TextStyle(
                      fontSize: fontSize * 0.8,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          SizedBox(height: padding * 0.3),
          // - / + 按钮与滑块
          Row(
            children: [
              _buildStepButton(theme, padding, fontSize, iconColor,
                  Icons.remove_rounded, value > min, () => onChanged(value - step)),
              Expanded(
                child: Slider(
                  value: value.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: ((max - min) ~/ step).clamp(1, 9999),
                  activeColor: iconColor,
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
              _buildStepButton(theme, padding, fontSize, iconColor,
                  Icons.add_rounded, value < max, () => onChanged(value + step)),
            ],
          ),
        ],
      ),
    );
  }

  /// 步进按钮（- / +）
  Widget _buildStepButton(ThemeData theme, double padding, double fontSize,
      Color color, IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(padding * 0.3),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: enabled
                ? color
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            size: fontSize * 1.1),
      ),
    );
  }

  /// 分隔线
  Widget _buildDivider(ThemeData theme, double padding) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}

/// 色盲辅助模式选项数据
class _ColorBlindOption {
  /// 色盲模式枚举
  final ColorBlindMode mode;

  /// 显示名称
  final String label;

  /// 简短描述
  final String desc;

  /// 预览色块（用于直观展示该模式下的关键色）
  final List<Color> previewColors;

  const _ColorBlindOption({
    required this.mode,
    required this.label,
    required this.desc,
    required this.previewColors,
  });
}
