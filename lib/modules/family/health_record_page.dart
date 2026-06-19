import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/core/constants/medical_constants.dart';
import 'package:yanji/core/providers/theme_provider.dart';
import 'package:yanji/data/models/family_member.dart';
import 'package:yanji/data/models/health_record.dart';
import 'package:yanji/data/repositories/family_member_repository.dart';
import 'package:yanji/data/repositories/health_record_repository.dart';
import 'package:yanji/modules/family/family_constants.dart';
import 'package:yanji/widgets/sensitive_data.dart';

/// 合并后的记录组（同时间 ±5 分钟内的多条记录合并）
class _RecordGroup {
  final DateTime time;
  final List<HealthRecord> records;

  _RecordGroup(this.time, this.records);

  bool get hasAbnormal => records.any((r) => r.isAbnormal);
}

/// 日期分组（今天 / 昨天 / M月d日）
class _DateSection {
  final String label;
  final List<_RecordGroup> groups;

  _DateSection(this.label, this.groups);
}

/// 健康指标记录页
///
/// 设计意图：长辈每天早上测完血压心率后打开此页记录。
/// 页面必须清晰、有条理：顶部概览一眼掌握健康状况，
/// 按日期分组的历史记录避免混乱，同时间的血压+心率合并显示。
class HealthRecordPage extends StatefulWidget {
  final String memberId;

  const HealthRecordPage({super.key, required this.memberId});

  @override
  State<HealthRecordPage> createState() => _HealthRecordPageState();
}

class _HealthRecordPageState extends State<HealthRecordPage> {
  final FamilyMemberRepository _memberRepo = FamilyMemberRepository();
  final HealthRecordRepository _healthRepo = HealthRecordRepository();

  FamilyMember? _member;
  List<HealthRecord> _records = [];
  bool _isLoading = true;

  /// 筛选类型：全部 | 血压 | 心率 | 服药
  String _filterType = '全部';
  /// 只看异常
  bool _onlyAbnormal = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载成员和健康记录
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final member = await _memberRepo.getMemberById(widget.memberId);
      final records = await _healthRepo.getRecordsByMember(widget.memberId);
      records.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
      if (!mounted) return;
      setState(() {
        _member = member;
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// 安全解析日期字符串，失败返回 null
  DateTime? _tryParseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  // ==================== 数据处理 ====================

  /// 计算健康概览统计：累计记录数、连续正常天数、近7天异常次数
  ({int total, int normalDays, int abnormal7d}) _computeStats() {
    final total = _records.length;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final abnormal7d = _records.where((r) {
      final t = _tryParseDate(r.measuredAt);
      if (t == null) return false;
      return t.isAfter(sevenDaysAgo) && r.isAbnormal;
    }).length;

    // 连续正常天数：从今天往前，遇到有异常的日期就停
    final abnormalDates = _records
        .where((r) => r.isAbnormal)
        .map((r) => _tryParseDate(r.measuredAt))
        .where((t) => t != null)
        .map((t) => DateTime(t!.year, t.month, t.day))
        .toSet();

    int normalDays = 0;
    var check = DateTime(now.year, now.month, now.day);
    while (!abnormalDates.contains(check) && normalDays < 365) {
      normalDays++;
      check = check.subtract(const Duration(days: 1));
    }

    return (total: total, normalDays: normalDays, abnormal7d: abnormal7d);
  }

  /// 筛选 + 合并 + 日期分组，返回最终展示数据
  List<_DateSection> _buildDisplayData() {
    var filtered = _records;
    if (_filterType != '全部') {
      filtered = filtered.where((r) => r.type == _filterType).toList();
    }
    if (_onlyAbnormal) {
      filtered = filtered.where((r) => r.isAbnormal).toList();
    }

    final groups = _mergeRecords(filtered);
    return _groupByDate(groups);
  }

  /// 合并同时间（±5分钟）且类型不同的记录
  List<_RecordGroup> _mergeRecords(List<HealthRecord> records) {
    if (records.isEmpty) return [];

    final sorted = List<HealthRecord>.from(records)
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

    final groups = <_RecordGroup>[];
    var current = <HealthRecord>[sorted.first];
    var currentTime = _tryParseDate(sorted.first.measuredAt) ?? DateTime.now();

    for (var i = 1; i < sorted.length; i++) {
      final record = sorted[i];
      final recordTime = _tryParseDate(record.measuredAt) ?? DateTime.now();
      final diff = currentTime.difference(recordTime).inMinutes.abs();
      final existingTypes = current.map((r) => r.type).toSet();

      if (diff <= 5 && !existingTypes.contains(record.type)) {
        current.add(record);
      } else {
        groups.add(_RecordGroup(currentTime, current));
        current = [record];
        currentTime = recordTime;
      }
    }
    groups.add(_RecordGroup(currentTime, current));
    return groups;
  }

  /// 按日期分组：今天 / 昨天 / M月d日
  List<_DateSection> _groupByDate(List<_RecordGroup> groups) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final sections = <_DateSection>[];
    String? currentLabel;
    List<_RecordGroup> currentGroups = [];

    for (final group in groups) {
      final label = _dateLabel(group.time, today, yesterday);
      if (label != currentLabel) {
        if (currentGroups.isNotEmpty) {
          sections.add(_DateSection(currentLabel!, currentGroups));
        }
        currentLabel = label;
        currentGroups = [group];
      } else {
        currentGroups.add(group);
      }
    }
    if (currentGroups.isNotEmpty) {
      sections.add(_DateSection(currentLabel!, currentGroups));
    }
    return sections;
  }

  /// 日期标签：今天 / 昨天 / M月d日
  String _dateLabel(DateTime time, DateTime today, DateTime yesterday) {
    final date = DateTime(time.year, time.month, time.day);
    if (date == today) return '今天';
    if (date == yesterday) return '昨天';
    return '${time.month}月${time.day}日';
  }

  // ==================== 业务逻辑 ====================

  /// 判断血压等级
  int _getBloodPressureGrade(int systolic, int diastolic) {
    if (systolic >= MedicalConstants.systolicGrade2Min ||
        diastolic >= MedicalConstants.diastolicGrade2Min) {
      return FamilyConstants.grade2;
    } else if (systolic >= MedicalConstants.systolicGrade1Min ||
        diastolic >= MedicalConstants.diastolicGrade1Min) {
      return FamilyConstants.grade1;
    }
    return FamilyConstants.gradeNormal;
  }

  /// 血压异常说明
  String _getBloodPressureDesc(int grade) {
    if (grade == FamilyConstants.grade2) {
      return MedicalConstants.hypertensionGrade2Desc;
    } else if (grade == FamilyConstants.grade1) {
      return MedicalConstants.hypertensionGrade1Desc;
    }
    return '血压正常';
  }

  /// 心率异常说明
  String _getHeartRateDesc(int heartRate) {
    if (heartRate > MedicalConstants.heartRateNormalMax) {
      return MedicalConstants.heartRateHighDesc;
    } else if (heartRate < MedicalConstants.heartRateNormalMin) {
      return MedicalConstants.heartRateLowDesc;
    }
    return '心率正常';
  }

  // ==================== 录入弹窗 ====================

  /// 显示血压录入弹窗
  void _showBloodPressureDialog() {
    final systolicCtrl = TextEditingController();
    final diastolicCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('录入血压'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: systolicCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '收缩压（高压 mmHg）',
                hintText: '如：120',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: diastolicCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '舒张压（低压 mmHg）',
                hintText: '如：80',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () =>
                _saveBloodPressure(systolicCtrl.text, diastolicCtrl.text, ctx),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 保存血压记录
  Future<void> _saveBloodPressure(
      String sysText, String diaText, BuildContext ctx) async {
    final systolic = int.tryParse(sysText);
    final diastolic = int.tryParse(diaText);

    if (systolic == null || diastolic == null) {
      _showSnackBar('请输入有效数字', isError: true);
      return;
    }
    if (systolic <= 0 || diastolic <= 0) {
      _showSnackBar('数值必须大于0', isError: true);
      return;
    }

    final grade = _getBloodPressureGrade(systolic, diastolic);
    final isAbnormal = grade != FamilyConstants.gradeNormal;
    final desc = _getBloodPressureDesc(grade);
    final now = DateTime.now();

    await _healthRepo.addRecord(HealthRecord(
      id: const Uuid().v4(),
      memberId: widget.memberId,
      type: '血压',
      value: '$systolic/$diastolic',
      unit: 'mmHg',
      isAbnormal: isAbnormal,
      abnormalDesc: isAbnormal ? desc : null,
      measuredAt: now.toIso8601String(),
      createdAt: now.toIso8601String(),
    ));

    if (ctx.mounted) Navigator.pop(ctx);
    if (mounted) {
      _loadData();
      _showSnackBar(isAbnormal ? '已记录，$desc' : '记录成功');
    }
  }

  /// 显示心率录入弹窗
  void _showHeartRateDialog() {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('录入心率'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '心率（次/分钟）',
            hintText: '如：72',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _saveHeartRate(ctrl.text, ctx),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 保存心率记录
  Future<void> _saveHeartRate(String text, BuildContext ctx) async {
    final heartRate = int.tryParse(text);
    if (heartRate == null || heartRate <= 0) {
      _showSnackBar('请输入有效心率', isError: true);
      return;
    }

    final isAbnormal = heartRate < MedicalConstants.heartRateNormalMin ||
        heartRate > MedicalConstants.heartRateNormalMax;
    final desc = _getHeartRateDesc(heartRate);
    final now = DateTime.now();

    await _healthRepo.addRecord(HealthRecord(
      id: const Uuid().v4(),
      memberId: widget.memberId,
      type: '心率',
      value: heartRate.toString(),
      unit: '次/分钟',
      isAbnormal: isAbnormal,
      abnormalDesc: isAbnormal ? desc : null,
      measuredAt: now.toIso8601String(),
      createdAt: now.toIso8601String(),
    ));

    if (ctx.mounted) Navigator.pop(ctx);
    if (mounted) {
      _loadData();
      _showSnackBar(isAbnormal ? '已记录，$desc' : '记录成功');
    }
  }

  /// 服药打卡
  Future<void> _medicationCheckIn() async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    final todayMed =
        _records.where((r) => r.type == '服药' && r.measuredAt.startsWith(todayStr));

    if (todayMed.isNotEmpty) {
      _showSnackBar('今日已服药打卡');
      return;
    }

    await _healthRepo.addRecord(HealthRecord(
      id: const Uuid().v4(),
      memberId: widget.memberId,
      type: '服药',
      value: '已服药',
      unit: '',
      isAbnormal: false,
      measuredAt: now.toIso8601String(),
      createdAt: now.toIso8601String(),
    ));
    if (mounted) {
      _loadData();
      _showSnackBar('服药打卡成功');
    }
  }

  // ==================== 删除与导出 ====================

  /// 删除记录组（二次确认）
  Future<void> _deleteGroup(_RecordGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('删除', style: TextStyle(color: AppColors.textLight)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    for (final r in group.records) {
      await _healthRepo.deleteRecord(r.id);
    }
    if (mounted) {
      _loadData();
      _showSnackBar('已删除');
    }
  }

  /// 导出 CSV（所有平台统一使用文本分享）
  Future<void> _exportCsv() async {
    if (_records.isEmpty) {
      _showSnackBar('暂无记录可导出', isError: true);
      return;
    }

    final csv = _generateCsv();
    final name = _member?.name ?? '成员';
    await Share.share(csv, subject: '$name 健康档案导出');
  }

  /// 生成 CSV 字符串
  String _generateCsv() {
    final buf = StringBuffer();
    buf.writeln(FamilyConstants.csvHeaders.join(','));
    for (final r in _records) {
      final row = [
        r.type,
        r.value,
        r.unit,
        r.isAbnormal ? '异常' : '正常',
        r.abnormalDesc ?? '',
        r.measuredAt,
      ].map((s) => '"$s"').join(',');
      buf.writeln(row);
    }
    return buf.toString();
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

  /// FAB 点击弹出三个选项
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final fontSize = MediaQuery.of(ctx).textScaler.scale(15);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('快速记录',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildSheetOption(
                  ctx: ctx,
                  icon: Icons.favorite,
                  color: AppColors.error,
                  label: '录血压',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showBloodPressureDialog();
                  },
                  fontSize: fontSize,
                ),
                _buildSheetOption(
                  ctx: ctx,
                  icon: Icons.monitor_heart,
                  color: AppColors.warning,
                  label: '录心率',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showHeartRateDialog();
                  },
                  fontSize: fontSize,
                ),
                _buildSheetOption(
                  ctx: ctx,
                  icon: Icons.medication,
                  color: AppColors.success,
                  label: '服药打卡',
                  onTap: () {
                    Navigator.pop(ctx);
                    _medicationCheckIn();
                  },
                  fontSize: fontSize,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建底部弹窗单个选项
  Widget _buildSheetOption({
    required BuildContext ctx,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    required double fontSize,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.08),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: fontSize * 1.4),
            ),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(
                    fontSize: fontSize * 1.1, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isElder = themeProvider.elderMode;
    final sw = MediaQuery.of(context).size.width;
    final padding = sw * 0.045;
    final fontSize = MediaQuery.of(context).textScaler.scale(14);
    final memberName = _member?.name ?? '成员';

    return Scaffold(
      appBar: AppBar(title: Text('$memberName 健康档案'), actions: [
        IconButton(
          onPressed: () => context.push('/family/chart/${widget.memberId}',
              extra: {'memberName': memberName}),
          icon: const Icon(Icons.show_chart),
          tooltip: '趋势分析',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _records.isEmpty
                  ? _buildEmptyState(context, padding, fontSize)
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                          padding, padding * 0.5, padding, padding * 2),
                      children: [
                        _buildOverview(context, padding, fontSize, isElder),
                        SizedBox(height: padding * 0.6),
                        _buildFilterBar(context, padding, fontSize),
                        SizedBox(height: padding * 0.6),
                        _buildGroupedRecords(context, padding, fontSize),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        tooltip: '添加记录',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 顶部健康概览：统计 + 快捷按钮
  Widget _buildOverview(
      BuildContext context, double padding, double fontSize, bool isElder) {
    final theme = Theme.of(context);
    final stats = _computeStats();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('健康概览',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: padding * 0.6),
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                  context,
                  padding,
                  fontSize,
                  icon: Icons.assignment_outlined,
                  value: '${stats.total}',
                  label: '累计记录',
                  color: theme.colorScheme.primary,
                )),
                SizedBox(width: padding * 0.4),
                Expanded(
                    child: _buildStatCard(
                  context,
                  padding,
                  fontSize,
                  icon: Icons.check_circle_outline,
                  value: '${stats.normalDays}',
                  label: '连续正常',
                  color: AppColors.success,
                )),
                SizedBox(width: padding * 0.4),
                Expanded(
                    child: _buildStatCard(
                  context,
                  padding,
                  fontSize,
                  icon: Icons.warning_amber_outlined,
                  value: '${stats.abnormal7d}',
                  label: '近7天异常',
                  color: stats.abnormal7d > 0
                      ? AppColors.error
                      : theme.colorScheme.primary,
                )),
              ],
            ),
            SizedBox(height: padding * 0.6),
            Row(
              children: [
                Expanded(
                  child: _buildQuickButton(
                    context,
                    padding,
                    fontSize,
                    isElder,
                    icon: Icons.show_chart,
                    label: '趋势图',
                    onTap: () => context.push('/family/chart/${widget.memberId}',
                        extra: {'memberName': _member?.name ?? '成员'}),
                  ),
                ),
                SizedBox(width: padding * 0.4),
                Expanded(
                  child: _buildQuickButton(
                    context,
                    padding,
                    fontSize,
                    isElder,
                    icon: Icons.download_outlined,
                    label: '导出CSV',
                    onTap: _exportCsv,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 单个统计卡片
  Widget _buildStatCard(BuildContext context, double padding, double fontSize,
      {required IconData icon,
      required String value,
      required String label,
      required Color color}) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: padding * 0.5, horizontal: padding * 0.3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: fontSize * 1.5),
          SizedBox(height: padding * 0.2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: fontSize * 1.6,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  /// 快捷按钮
  Widget _buildQuickButton(BuildContext context, double padding, double fontSize,
      bool isElder,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return SizedBox(
      height: isElder ? 56 : 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: fontSize * 1.1),
        label: Text(label, style: TextStyle(fontSize: fontSize)),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// 筛选栏：Tab + 只看异常开关
  Widget _buildFilterBar(
      BuildContext context, double padding, double fontSize) {
    final theme = Theme.of(context);
    final types = ['全部', '血压', '心率', '服药'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: padding * 0.6, vertical: padding * 0.5),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: types
                    .map((t) => Padding(
                          padding: EdgeInsets.only(right: padding * 0.3),
                          child: _buildFilterChip(
                              context, fontSize, t, _filterType == t),
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: padding * 0.3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('只看异常',
                    style: TextStyle(
                        fontSize: fontSize, color: theme.colorScheme.onSurface)),
                Switch(
                  value: _onlyAbnormal,
                  onChanged: (v) => setState(() => _onlyAbnormal = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 筛选 Chip
  Widget _buildFilterChip(
      BuildContext context, double fontSize, String label, bool selected) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _filterType = label),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: fontSize * 1.0, vertical: fontSize * 0.5),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// 分组历史记录
  Widget _buildGroupedRecords(
      BuildContext context, double padding, double fontSize) {
    final sections = _buildDisplayData();

    if (sections.isEmpty) {
      return _buildEmptyFilterState(context, padding, fontSize);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections
          .map((s) => _buildDateSection(context, padding, fontSize, s))
          .toList(),
    );
  }

  /// 单个日期分组
  Widget _buildDateSection(
      BuildContext context, double padding, double fontSize, _DateSection section) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
              top: padding * 0.4, bottom: padding * 0.4),
          child: Text(
            section.label,
            style: TextStyle(
              fontSize: fontSize * 1.15,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ...section.groups
            .map((g) => _buildRecordGroupCard(context, padding, fontSize, g)),
      ],
    );
  }

  /// 合并记录卡片（核心：同时间血压+心率合并显示）
  Widget _buildRecordGroupCard(
      BuildContext context, double padding, double fontSize, _RecordGroup group) {
    final theme = Theme.of(context);
    final isAbnormal = group.hasAbnormal;
    final timeStr = DateFormat('HH:mm').format(group.time);

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: padding * 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isAbnormal
            ? BorderSide(color: AppColors.error.withValues(alpha: 0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(padding * 0.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: fontSize * 0.95,
                        color: theme.colorScheme.onSurfaceVariant),
                    SizedBox(width: padding * 0.2),
                    Text(timeStr,
                        style: TextStyle(
                            fontSize: fontSize * 0.95,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                IconButton(
                  onPressed: () => _deleteGroup(group),
                  icon: Icon(Icons.delete_outline,
                      size: fontSize * 1.1,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5)),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            SizedBox(height: padding * 0.2),
            // 每条记录
            ...group.records.map((r) =>
                _buildRecordLine(context, padding, fontSize, r)),
          ],
        ),
      ),
    );
  }

  /// 单条记录行（在合并卡片内）
  Widget _buildRecordLine(
      BuildContext context, double padding, double fontSize, HealthRecord record) {
    final theme = Theme.of(context);
    final (icon, color) = _typeStyle(record.type);
    final isAbn = record.isAbnormal;

    return Padding(
      padding: EdgeInsets.only(bottom: padding * 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(padding * 0.3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: fontSize * 1.3),
          ),
          SizedBox(width: padding * 0.4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(record.type,
                        style: TextStyle(
                            fontSize: fontSize * 0.9,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                    SizedBox(width: padding * 0.3),
                    // 敏感数据（血压/心率/体重）模糊显示
                    SensitiveData(
                      child: Text('${record.value} ${record.unit}',
                          style: TextStyle(
                              fontSize: fontSize * 1.25,
                              fontWeight: FontWeight.bold,
                              color: isAbn ? AppColors.error : theme.colorScheme.onSurface)),
                    ),
                    const Spacer(),
                    if (isAbn)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: padding * 0.25, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('异常',
                            style: TextStyle(
                                fontSize: fontSize * 0.75,
                                color: AppColors.error,
                                fontWeight: FontWeight.bold)),
                      )
                    else
                      Icon(Icons.check_circle,
                          size: fontSize * 0.9, color: AppColors.success),
                  ],
                ),
                if (isAbn && record.abnormalDesc != null) ...[
                  SizedBox(height: padding * 0.15),
                  Container(
                    padding: EdgeInsets.all(padding * 0.3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: fontSize * 0.9, color: AppColors.error),
                        SizedBox(width: padding * 0.2),
                        Expanded(
                          child: Text(record.abnormalDesc ?? '',
                              style: TextStyle(
                                  fontSize: fontSize * 0.85,
                                  color: AppColors.error,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 记录类型对应的图标和颜色
  (IconData, Color) _typeStyle(String type) {
    switch (type) {
      case '血压':
        return (Icons.favorite, AppColors.error);
      case '心率':
        return (Icons.monitor_heart, AppColors.warning);
      case '服药':
        return (Icons.medication, AppColors.success);
      case '步数':
        return (Icons.directions_walk, AppColors.info);
      default:
        return (Icons.health_and_safety, AppColors.textSecondary);
    }
  }

  /// 空状态（无任何记录）
  Widget _buildEmptyState(
      BuildContext context, double padding, double fontSize) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        SizedBox(height: padding * 3),
        Icon(Icons.health_and_safety_outlined,
            size: fontSize * 6,
            color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        SizedBox(height: padding),
        Text('暂无健康记录',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: padding * 0.3),
        Text('点击右下角 + 按钮开始记录',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: fontSize, color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  /// 筛选后无结果的空状态
  Widget _buildEmptyFilterState(
      BuildContext context, double padding, double fontSize) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(padding * 2),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_outlined,
              size: fontSize * 4,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          SizedBox(height: padding * 0.5),
          Text('没有符合条件的记录',
              style: TextStyle(
                  fontSize: fontSize, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
