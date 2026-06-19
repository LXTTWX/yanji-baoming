import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/data/models/emergency_card.dart';
import 'package:yanji/data/models/health_record.dart';
import 'package:yanji/data/models/user_profile.dart';
import 'package:yanji/data/repositories/emergency_card_repository.dart';
import 'package:yanji/data/repositories/health_record_repository.dart';
import 'package:yanji/data/repositories/user_profile_repository.dart';

/// 急救卡页面
///
/// 三种模式：
/// - [EmergencyCardMode.view]：查看模式（默认），分层展示急救信息
/// - [EmergencyCardMode.edit]：编辑模式，编辑所有字段
/// - [EmergencyCardMode.lock]：锁屏查看模式，只显示关键信息（血型、过敏、第一联系人）
class EmergencyCardPage extends StatefulWidget {
  /// 页面模式
  final EmergencyCardMode mode;

  /// 构造函数
  const EmergencyCardPage({super.key, this.mode = EmergencyCardMode.view});

  @override
  State<EmergencyCardPage> createState() => _EmergencyCardPageState();
}

/// 急救卡页面模式
enum EmergencyCardMode {
  /// 查看模式
  view,
  /// 编辑模式
  edit,
  /// 锁屏查看模式（不解锁也能看）
  lock,
}

class _EmergencyCardPageState extends State<EmergencyCardPage> {
  final EmergencyCardRepository _emergencyRepo = EmergencyCardRepository();
  final UserProfileRepository _profileRepo = UserProfileRepository();
  final HealthRecordRepository _healthRepo = HealthRecordRepository();

  bool _isLoading = true;
  EmergencyCard? _card;
  List<EmergencyContact> _contacts = [];
  UserProfile? _profile;
  List<HealthRecord> _medications = [];

  // 编辑模式临时数据
  late int _editBloodType;
  late TextEditingController _allergiesController;
  late TextEditingController _medicalNotesController;
  late TextEditingController _languageController;
  late int _editOrganDonor;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载急救卡所有数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final card = await _emergencyRepo.getCard();
      final contacts = await _emergencyRepo.getAllContacts();
      final profile = await _profileRepo.getProfile();

      // 获取最近30天的服药记录
      final allHealthRecords = await _healthRepo.getAllRecords();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final meds = allHealthRecords.where((r) {
        if (r.type != '服药') return false;
        try {
          final d = DateTime.parse(r.measuredAt);
          return d.isAfter(thirtyDaysAgo);
        } catch (_) {
          return false;
        }
      }).toList();
      meds.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

      setState(() {
        _card = card;
        _contacts = contacts;
        _profile = profile;
        _medications = meds.take(5).toList();
        _isLoading = false;

        // 初始化编辑控制器
        _editBloodType = card.bloodType;
        _editOrganDonor = card.organDonor;
        _allergiesController = TextEditingController(text: card.allergies);
        _medicalNotesController =
            TextEditingController(text: card.medicalNotes);
        _languageController =
            TextEditingController(text: card.preferredLanguage);
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  /// 拨打电话
  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法拨号：$phone')),
      );
    }
  }

  /// 跳转到健身档案编辑身高体重
  void _goToProfileEdit() {
    context.push('/fitness/profile');
  }

  /// 保存急救卡信息
  Future<void> _saveCard() async {
    final card = _card;
    if (card == null) return;
    card.bloodType = _editBloodType;
    card.allergies = _allergiesController.text.trim();
    card.organDonor = _editOrganDonor;
    card.medicalNotes = _medicalNotesController.text.trim();
    card.preferredLanguage = _languageController.text.trim();
    await _emergencyRepo.saveCard(card);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('急救卡已保存')),
      );
      setState(() {});
    }
  }

  /// 切换编辑/查看模式
  void _toggleEditMode() {
    if (widget.mode != EmergencyCardMode.view) return;
    if (_card == null) return;
    _editBloodType = _card!.bloodType;
    _editOrganDonor = _card!.organDonor;
    _allergiesController.text = _card!.allergies;
    _medicalNotesController.text = _card!.medicalNotes;
    _languageController.text = _card!.preferredLanguage;
    setState(() {});
  }

  /// 获取血型显示文本
  String _bloodTypeText(int type) {
    switch (type) {
      case 1:
        return 'A';
      case 2:
        return 'B';
      case 3:
        return 'AB';
      case 4:
        return 'O';
      default:
        return '?';
    }
  }

  /// 获取血型颜色
  Color _bloodTypeColor(int type) {
    switch (type) {
      case 1:
        return const Color(0xFFE53935); // A - 红
      case 2:
        return const Color(0xFF1E88E5); // B - 蓝
      case 3:
        return const Color(0xFF8E24AA); // AB - 紫
      case 4:
        return const Color(0xFF43A047); // O - 绿
      default:
        return const Color(0xFF9E9E9E); // 未知 - 灰
    }
  }

  /// 计算年龄（从 UserProfile.age 读取）
  String _getAgeString() {
    final age = _profile?.age;
    if (age != null && age > 0) return '$age 岁';
    return '未知';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sw = MediaQuery.of(context).size.width;
    final padding = sw * 0.045;
    // 急救卡页面字号比普通页面大 15%，确保紧急时能看清
    final baseFontSize = MediaQuery.of(context).textScaler.scale(14) * 1.15;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mode == EmergencyCardMode.lock
              ? '急救信息'
              : '医疗急救卡'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 锁屏查看模式：只显示关键信息
    if (widget.mode == EmergencyCardMode.lock) {
      return _buildLockScreenView(theme, padding, baseFontSize);
    }

    final isEditMode = widget.mode == EmergencyCardMode.edit;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '编辑急救卡' : '医疗急救卡'),
        actions: [
          if (widget.mode == EmergencyCardMode.view)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: '编辑',
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            padding, padding * 0.5, padding, padding * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一层：血型大圆章 + 过敏警报
            _buildEmergencyTopSection(theme, padding, baseFontSize, isEditMode),
            SizedBox(height: padding * 0.7),

            // 第二层：基础信息（姓名/年龄/身高体重 + 最近用药）
            _buildBasicInfoSection(theme, padding, baseFontSize),
            SizedBox(height: padding * 0.7),

            // 紧急联系人列表
            _buildContactsSection(theme, padding, baseFontSize),
            SizedBox(height: padding * 0.7),

            // 第三层：补充信息（器官捐献/语言/备注）
            _buildSupplementarySection(theme, padding, baseFontSize, isEditMode),
            SizedBox(height: padding * 0.7),

            // 信息完整度提示
            _buildCompletenessHint(theme, padding, baseFontSize),

            // 编辑模式下的保存按钮
            if (isEditMode) ...[
              SizedBox(height: padding * 0.7),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveCard,
                  icon: const Icon(Icons.check),
                  label: const Text('保存急救卡'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: padding * 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== 第一层：紧急信息（血型 + 过敏） ====================

  /// 顶部紧急信息区：血型大圆章 + 过敏警报
  Widget _buildEmergencyTopSection(
      ThemeData theme, double padding, double fontSize, bool isEditMode) {
    final card = _card;
    if (card == null) return const SizedBox.shrink();

    final bloodColor = _bloodTypeColor(card.bloodType);
    final bloodText = _bloodTypeText(card.bloodType);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.error.withValues(alpha: 0.08),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // 紧急标识
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emergency, color: AppColors.error, size: fontSize * 1.5),
              SizedBox(width: padding * 0.3),
              Text(
                '紧急医疗信息',
                style: TextStyle(
                  fontSize: fontSize * 1.3,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: padding * 0.8),

          // 血型大圆章 + 过敏警报并排
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 血型圆章
              Expanded(
                flex: 2,
                child: _buildBloodTypeBadge(
                  bloodColor,
                  bloodText,
                  padding,
                  fontSize,
                  isEditMode,
                ),
              ),
              SizedBox(width: padding * 0.5),
              // 过敏警报
              Expanded(
                flex: 3,
                child: _buildAllergyAlert(
                  theme,
                  card.allergies,
                  padding,
                  fontSize,
                  isEditMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 血型大圆章（类似医疗手环）
  Widget _buildBloodTypeBadge(Color color, String text, double padding,
      double fontSize, bool isEditMode) {
    return Column(
      children: [
        Container(
          width: fontSize * 5,
          height: fontSize * 5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '血型',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: fontSize * 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: fontSize * 0.2),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize * 2.5,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        if (isEditMode) ...[
          SizedBox(height: padding * 0.4),
          _buildBloodTypeSelector(padding, fontSize),
        ],
      ],
    );
  }

  /// 血型选择器（编辑模式）
  Widget _buildBloodTypeSelector(double padding, double fontSize) {
    const types = [0, 1, 2, 3, 4];
    const labels = ['未知', 'A', 'B', 'AB', 'O'];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: padding * 0.3,
      runSpacing: padding * 0.3,
      children: [
        for (int i = 0; i < types.length; i++)
          GestureDetector(
            onTap: () => setState(() => _editBloodType = types[i]),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: padding * 0.4,
                vertical: padding * 0.2,
              ),
              decoration: BoxDecoration(
                color: _editBloodType == types[i]
                    ? _bloodTypeColor(types[i])
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _editBloodType == types[i]
                      ? _bloodTypeColor(types[i])
                      : Colors.transparent,
                ),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: _editBloodType == types[i]
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize * 0.85,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 过敏警报卡片
  Widget _buildAllergyAlert(ThemeData theme, String allergies, double padding,
      double fontSize, bool isEditMode) {
    final hasAllergies = allergies.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding * 0.6),
      decoration: BoxDecoration(
        color: hasAllergies
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasAllergies
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.success.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasAllergies ? Icons.warning_amber_rounded : Icons.check_circle,
                color: hasAllergies ? AppColors.error : AppColors.success,
                size: fontSize * 1.3,
              ),
              SizedBox(width: padding * 0.3),
              Text(
                hasAllergies ? '过敏史' : '无过敏史',
                style: TextStyle(
                  fontSize: fontSize * 1.1,
                  fontWeight: FontWeight.bold,
                  color: hasAllergies ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          if (hasAllergies && !isEditMode) ...[
            SizedBox(height: padding * 0.3),
            Text(
              allergies,
              style: TextStyle(
                fontSize: fontSize * 1.05,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ],
          if (isEditMode) ...[
            SizedBox(height: padding * 0.3),
            TextField(
              controller: _allergiesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '每行一条，如：青霉素、海鲜',
                hintStyle: TextStyle(fontSize: fontSize * 0.85),
                contentPadding: EdgeInsets.all(padding * 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== 第二层：基础信息 ====================

  /// 基础信息区：姓名/年龄/身高体重 + 最近用药
  Widget _buildBasicInfoSection(
      ThemeData theme, double padding, double fontSize) {
    final profile = _profile;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding * 0.8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '基本信息',
            style: TextStyle(
              fontSize: fontSize * 1.1,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: padding * 0.5),
          // 姓名 + 年龄
          _buildInfoRow(
            theme,
            padding,
            fontSize,
            icon: Icons.person_outline,
            label: '姓名',
            value: profile?.nickname ?? '未填写',
          ),
          Divider(
              height: padding * 0.6,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          _buildInfoRow(
            theme,
            padding,
            fontSize,
            icon: Icons.cake_outlined,
            label: '年龄',
            value: _getAgeString(),
          ),
          Divider(
              height: padding * 0.6,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          // 身高体重（可跳转编辑）
          InkWell(
            onTap: _goToProfileEdit,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: padding * 0.2),
              child: Row(
                children: [
                  Icon(Icons.straighten_outlined,
                      color: theme.colorScheme.primary, size: fontSize * 1.3),
                  SizedBox(width: padding * 0.4),
                  Expanded(
                    child: Text('身高 / 体重',
                        style: TextStyle(
                            fontSize: fontSize * 0.9,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  Text(
                    '${profile?.height?.toStringAsFixed(0) ?? '--'} cm / ${profile?.weight?.toStringAsFixed(1) ?? '--'} kg',
                    style: TextStyle(
                        fontSize: fontSize * 1.05,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: padding * 0.2),
                  Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                      size: fontSize * 1.2),
                ],
              ),
            ),
          ),
          Divider(
              height: padding * 0.6,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          // 最近用药
          _buildMedicationList(theme, padding, fontSize),
        ],
      ),
    );
  }

  /// 信息行
  Widget _buildInfoRow(ThemeData theme, double padding, double fontSize,
      {required IconData icon,
      required String label,
      required String value}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding * 0.2),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: fontSize * 1.3),
          SizedBox(width: padding * 0.4),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: fontSize * 0.9,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize * 1.05, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// 最近用药列表（从服药打卡自动导入）
  Widget _buildMedicationList(
      ThemeData theme, double padding, double fontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding * 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_outlined,
                  color: AppColors.success, size: fontSize * 1.3),
              SizedBox(width: padding * 0.4),
              Expanded(
                child: Text('最近用药',
                    style: TextStyle(
                        fontSize: fontSize * 0.9,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              Text('近30天',
                  style: TextStyle(
                      fontSize: fontSize * 0.75,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6))),
            ],
          ),
          SizedBox(height: padding * 0.3),
          if (_medications.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding * 0.4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '暂无服药记录',
                style: TextStyle(
                    fontSize: fontSize * 0.85,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6)),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._medications.map((m) => Padding(
                  padding: EdgeInsets.only(bottom: padding * 0.2),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: fontSize * 0.9, color: AppColors.success),
                      SizedBox(width: padding * 0.3),
                      Expanded(
                        child: Text(
                          _formatMedicationDate(m.measuredAt),
                          style: TextStyle(
                              fontSize: fontSize * 0.9,
                              color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  /// 格式化服药日期
  String _formatMedicationDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return '${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} 已服药';
    } catch (_) {
      return '已服药';
    }
  }

  // ==================== 紧急联系人 ====================

  /// 紧急联系人列表
  Widget _buildContactsSection(
      ThemeData theme, double padding, double fontSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding * 0.8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone_outlined,
                  color: AppColors.error, size: fontSize * 1.3),
              SizedBox(width: padding * 0.4),
              Text('紧急联系人',
                  style: TextStyle(
                      fontSize: fontSize * 1.1, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (widget.mode == EmergencyCardMode.view)
                TextButton.icon(
                  onPressed: _showAddContactDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                ),
            ],
          ),
          SizedBox(height: padding * 0.5),
          if (_contacts.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding * 0.6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_add_outlined,
                      size: fontSize * 2,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4)),
                  SizedBox(height: padding * 0.3),
                  Text('尚未添加紧急联系人',
                      style: TextStyle(
                          fontSize: fontSize * 0.9,
                          color: theme.colorScheme.onSurfaceVariant)),
                  SizedBox(height: padding * 0.2),
                  Text('紧急时医护人员会联系此人',
                      style: TextStyle(
                          fontSize: fontSize * 0.8,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6))),
                ],
              ),
            )
          else
            ..._contacts
                .map((c) => _buildContactItem(theme, padding, fontSize, c)),
        ],
      ),
    );
  }

  /// 单个紧急联系人卡片
  Widget _buildContactItem(
      ThemeData theme, double padding, double fontSize, EmergencyContact c) {
    return Container(
      margin: EdgeInsets.only(bottom: padding * 0.3),
      padding: EdgeInsets.all(padding * 0.5),
      decoration: BoxDecoration(
        color: c.isPrimary
            ? AppColors.error.withValues(alpha: 0.05)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: c.isPrimary
            ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: fontSize * 1.3,
            backgroundColor: c.isPrimary
                ? AppColors.error.withValues(alpha: 0.15)
                : theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(
              c.isPrimary ? Icons.star : Icons.person_outline,
              color: c.isPrimary ? AppColors.error : theme.colorScheme.primary,
              size: fontSize * 1.4,
            ),
          ),
          SizedBox(width: padding * 0.4),
          // 姓名和关系
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c.name,
                        style: TextStyle(
                            fontSize: fontSize * 1.1,
                            fontWeight: FontWeight.bold)),
                    if (c.isPrimary) ...[
                      SizedBox(width: padding * 0.2),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: padding * 0.2,
                            vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('第一联系人',
                            style: TextStyle(
                                fontSize: fontSize * 0.65,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Text(c.relationship,
                    style: TextStyle(
                        fontSize: fontSize * 0.85,
                        color: theme.colorScheme.onSurfaceVariant)),
                if (c.note != null && c.note!.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(c.note!,
                      style: TextStyle(
                          fontSize: fontSize * 0.75,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7))),
                ],
              ],
            ),
          ),
          // 拨号按钮
          InkWell(
            onTap: () => _callPhone(c.phone),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: EdgeInsets.all(padding * 0.4),
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.phone,
                  color: Colors.white, size: fontSize * 1.4),
            ),
          ),
          if (widget.mode == EmergencyCardMode.view) ...[
            SizedBox(width: padding * 0.2),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.5),
                  size: fontSize),
              onSelected: (value) =>
                  _handleContactAction(value, c),
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'setPrimary', child: Text('设为第一联系人')),
                const PopupMenuItem(
                    value: 'edit', child: Text('编辑')),
                const PopupMenuItem(
                    value: 'delete', child: Text('删除')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 处理联系人操作
  Future<void> _handleContactAction(
      String action, EmergencyContact contact) async {
    switch (action) {
      case 'setPrimary':
        contact.isPrimary = true;
        await _emergencyRepo.updateContact(contact);
        await _loadData();
        break;
      case 'edit':
        _showEditContactDialog(contact);
        break;
      case 'delete':
        _showDeleteConfirm(contact);
        break;
    }
  }

  /// 显示添加联系人对话框
  void _showAddContactDialog() {
    _showContactDialog(contact: null);
  }

  /// 显示编辑联系人对话框
  void _showEditContactDialog(EmergencyContact contact) {
    _showContactDialog(contact: contact);
  }

  /// 联系人编辑对话框
  void _showContactDialog({EmergencyContact? contact}) {
    final isEdit = contact != null;
    final nameController = TextEditingController(text: contact?.name ?? '');
    final relationController =
        TextEditingController(text: contact?.relationship ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final noteController = TextEditingController(text: contact?.note ?? '');
    bool isPrimary = contact?.isPrimary ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑联系人' : '添加紧急联系人'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: relationController,
                  decoration: const InputDecoration(
                    labelText: '关系（如：父亲、配偶、医生）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: '电话',
                    border: OutlineInputBorder(),
                    prefixText: '+86 ',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: '备注（选填）',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: isPrimary,
                  onChanged: (v) =>
                      setDialogState(() => isPrimary = v ?? false),
                  title: const Text('设为第一紧急联系人'),
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写姓名和电话')),
                  );
                  return;
                }
                final editContact = isEdit ? contact : null;
                if (editContact != null) {
                  editContact.name = nameController.text.trim();
                  editContact.relationship = relationController.text.trim();
                  editContact.phone = phoneController.text.trim();
                  editContact.note = noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim();
                  editContact.isPrimary = isPrimary;
                  await _emergencyRepo.updateContact(editContact);
                } else {
                  final now = DateTime.now().toIso8601String();
                  final newContact = EmergencyContact(
                    id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    relationship: relationController.text.trim().isEmpty
                        ? '联系人'
                        : relationController.text.trim(),
                    phone: phoneController.text.trim(),
                    isPrimary: isPrimary,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                    createdAt: now,
                  );
                  await _emergencyRepo.addContact(newContact);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadData();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 删除确认
  void _showDeleteConfirm(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除联系人'),
        content: Text('确定删除「${contact.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await _emergencyRepo.deleteContact(contact.id);
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadData();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // ==================== 第三层：补充信息 ====================

  /// 补充信息区：器官捐献/语言/备注
  Widget _buildSupplementarySection(
      ThemeData theme, double padding, double fontSize, bool isEditMode) {
    final card = _card;
    if (card == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding * 0.8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('补充医疗信息',
              style: TextStyle(
                  fontSize: fontSize * 1.1, fontWeight: FontWeight.bold)),
          SizedBox(height: padding * 0.5),
          // 器官捐献意愿
          _buildOrganDonorRow(theme, padding, fontSize, card.organDonor, isEditMode),
          Divider(
              height: padding * 0.6,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          // 习惯语言
          if (isEditMode)
            _buildLanguageEditRow(theme, padding, fontSize)
          else
            _buildInfoRow(
              theme,
              padding,
              fontSize,
              icon: Icons.language_outlined,
              label: '习惯语言',
              value: card.preferredLanguage,
            ),
          Divider(
              height: padding * 0.6,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          // 医疗备注
          if (isEditMode)
            _buildMedicalNotesEdit(theme, padding, fontSize)
          else
            _buildMedicalNotesView(theme, padding, fontSize, card.medicalNotes),
        ],
      ),
    );
  }

  /// 器官捐献意愿行
  Widget _buildOrganDonorRow(ThemeData theme, double padding, double fontSize,
      int current, bool isEditMode) {
    const labels = ['未填写', '愿意', '不愿意'];
    const colors = [Colors.grey, AppColors.success, AppColors.error];
    final label = labels[current.clamp(0, 2)];
    final color = colors[current.clamp(0, 2)];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding * 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_outline,
                  color: color, size: fontSize * 1.3),
              SizedBox(width: padding * 0.4),
              Expanded(
                child: Text('器官捐献意愿',
                    style: TextStyle(
                        fontSize: fontSize * 0.9,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              if (!isEditMode)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: padding * 0.3, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: fontSize * 0.9,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
            ],
          ),
          if (isEditMode) ...[
            SizedBox(height: padding * 0.3),
            Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) SizedBox(width: padding * 0.3),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _editOrganDonor = i),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: padding * 0.25),
                        decoration: BoxDecoration(
                          color: _editOrganDonor == i
                              ? colors[i]
                              : colors[i].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _editOrganDonor == i
                                ? colors[i]
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(labels[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSize * 0.85,
                              fontWeight: FontWeight.bold,
                              color: _editOrganDonor == i
                                  ? Colors.white
                                  : colors[i],
                            )),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 语言编辑行
  Widget _buildLanguageEditRow(
      ThemeData theme, double padding, double fontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding * 0.2),
      child: Row(
        children: [
          Icon(Icons.language_outlined,
              color: theme.colorScheme.primary, size: fontSize * 1.3),
          SizedBox(width: padding * 0.4),
          Expanded(
            child: Text('习惯语言',
                style: TextStyle(
                    fontSize: fontSize * 0.9,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          SizedBox(
            width: padding * 3,
            child: TextField(
              controller: _languageController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: padding * 0.3, vertical: padding * 0.2),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(fontSize: fontSize * 0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// 医疗备注查看
  Widget _buildMedicalNotesView(
      ThemeData theme, double padding, double fontSize, String notes) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding * 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt_outlined,
                  color: theme.colorScheme.primary, size: fontSize * 1.3),
              SizedBox(width: padding * 0.4),
              Text('医疗备注',
                  style: TextStyle(
                      fontSize: fontSize * 0.9,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          SizedBox(height: padding * 0.2),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding * 0.4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              notes.isEmpty ? '无' : notes,
              style: TextStyle(
                  fontSize: fontSize * 0.95,
                  color: notes.isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5)
                      : theme.colorScheme.onSurface,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 医疗备注编辑
  Widget _buildMedicalNotesEdit(ThemeData theme, double padding, double fontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding * 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt_outlined,
                  color: theme.colorScheme.primary, size: fontSize * 1.3),
              SizedBox(width: padding * 0.4),
              Text('医疗备注',
                  style: TextStyle(
                      fontSize: fontSize * 0.9,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          SizedBox(height: padding * 0.2),
          TextField(
            controller: _medicalNotesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '如：高血压病史、起搏器、糖尿病、手术史等',
              hintStyle: TextStyle(fontSize: fontSize * 0.85),
              contentPadding: EdgeInsets.all(padding * 0.4),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            style: TextStyle(fontSize: fontSize * 0.95),
          ),
        ],
      ),
    );
  }

  // ==================== 信息完整度提示 ====================

  /// 信息完整度提示
  Widget _buildCompletenessHint(
      ThemeData theme, double padding, double fontSize) {
    final card = _card;
    if (card == null) return const SizedBox.shrink();

    final missing = <String>[];
    if (card.bloodType == 0) missing.add('血型');
    if (card.allergies.isEmpty) missing.add('过敏史');
    if (_contacts.isEmpty) missing.add('紧急联系人');
    if (_profile?.age == null || _profile!.age! <= 0) missing.add('年龄');
    if (card.organDonor == 0) missing.add('器官捐献意愿');

    if (missing.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding * 0.6),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_outlined,
                color: AppColors.success, size: fontSize * 1.3),
            SizedBox(width: padding * 0.4),
            Expanded(
              child: Text('急救卡信息已完整',
                  style: TextStyle(
                      fontSize: fontSize * 0.95,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success)),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding * 0.6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: AppColors.warning, size: fontSize * 1.3),
              SizedBox(width: padding * 0.4),
              Text('建议补全以下信息',
                  style: TextStyle(
                      fontSize: fontSize * 0.95,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning)),
            ],
          ),
          SizedBox(height: padding * 0.3),
          Wrap(
            spacing: padding * 0.3,
            runSpacing: padding * 0.2,
            children: missing
                .map((m) => Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.3, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(m,
                          style: TextStyle(
                              fontSize: fontSize * 0.8,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ==================== 锁屏查看模式 ====================

  /// 锁屏查看模式：只显示最关键信息
  Widget _buildLockScreenView(
      ThemeData theme, double padding, double fontSize) {
    final card = _card;
    final primaryContact = _contacts.isNotEmpty ? _contacts.first : null;
    final profile = _profile;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              SizedBox(height: padding * 0.5),
              // 红十字标识
              Container(
                width: fontSize * 4,
                height: fontSize * 4,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emergency,
                    color: Colors.white, size: fontSize * 2.2),
              ),
              SizedBox(height: padding * 0.5),
              Text('紧急医疗信息',
                  style: TextStyle(
                      fontSize: fontSize * 1.6,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                      letterSpacing: 2)),
              SizedBox(height: padding * 0.3),
              Text('此信息无需解锁即可查看',
                  style: TextStyle(
                      fontSize: fontSize * 0.85,
                      color: Colors.grey[600])),
              SizedBox(height: padding),

              // 姓名
              if (profile != null) ...[
                Text(profile.nickname,
                    style: TextStyle(
                        fontSize: fontSize * 1.8,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: padding * 0.2),
                Text(_getAgeString(),
                    style: TextStyle(
                        fontSize: fontSize * 1.1, color: Colors.grey[700])),
                SizedBox(height: padding),
              ],

              // 血型大圆章
              if (card != null) ...[
                Container(
                  width: fontSize * 6,
                  height: fontSize * 6,
                  decoration: BoxDecoration(
                    color: _bloodTypeColor(card.bloodType),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _bloodTypeColor(card.bloodType)
                            .withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('血型',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: fontSize * 0.9)),
                      Text(_bloodTypeText(card.bloodType),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize * 3,
                              fontWeight: FontWeight.bold,
                              height: 1)),
                    ],
                  ),
                ),
                SizedBox(height: padding),
              ],

              // 过敏史（红色警报）
              if (card != null && card.allergies.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(padding * 0.6),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.white, size: fontSize * 1.5),
                          SizedBox(width: padding * 0.3),
                          Text('过敏史',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize * 1.2,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                        ],
                      ),
                      SizedBox(height: padding * 0.3),
                      Text(card.allergies,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize * 1.3,
                              fontWeight: FontWeight.bold,
                              height: 1.5)),
                    ],
                  ),
                ),
                SizedBox(height: padding),
              ],

              // 第一紧急联系人（大号拨号按钮）
              if (primaryContact != null) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(padding * 0.6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4),
                        width: 2),
                  ),
                  child: Column(
                    children: [
                      Text('紧急联系人',
                          style: TextStyle(
                              fontSize: fontSize * 0.9,
                              color: Colors.grey[600])),
                      SizedBox(height: padding * 0.2),
                      Text(primaryContact.name,
                          style: TextStyle(
                              fontSize: fontSize * 1.5,
                              fontWeight: FontWeight.bold)),
                      Text(primaryContact.relationship,
                          style: TextStyle(
                              fontSize: fontSize * 0.95,
                              color: Colors.grey[700])),
                      SizedBox(height: padding * 0.5),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _callPhone(primaryContact.phone),
                          icon: const Icon(Icons.phone, size: 28),
                          label: Text(primaryContact.phone,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: EdgeInsets.symmetric(
                                vertical: padding * 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: padding),
              ],

              // 医疗备注（如果有）
              if (card != null && card.medicalNotes.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(padding * 0.5),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.note_alt_outlined,
                              size: fontSize * 1.1, color: Colors.grey[700]),
                          SizedBox(width: padding * 0.2),
                          Text('医疗备注',
                              style: TextStyle(
                                  fontSize: fontSize * 0.9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700])),
                        ],
                      ),
                      SizedBox(height: padding * 0.2),
                      Text(card.medicalNotes,
                          style: TextStyle(
                              fontSize: fontSize * 1.05, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _medicalNotesController.dispose();
    _languageController.dispose();
    super.dispose();
  }
}
