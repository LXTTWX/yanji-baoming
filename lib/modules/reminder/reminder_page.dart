import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/data/models/reminder.dart';
import 'package:yanji/data/repositories/reminder_repository.dart';
import 'package:yanji/modules/reminder/notification_helper.dart';
import 'package:yanji/modules/reminder/reminder_constants.dart';
import 'package:uuid/uuid.dart';

/// 提醒管理主页面
class ReminderPage extends StatefulWidget {
  /// 构造函数
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final ReminderRepository _reminderRepo = ReminderRepository();
  final NotificationHelper _notificationHelper = NotificationHelper();
  
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载提醒数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reminders = await _reminderRepo.getAllReminders();
      reminders.sort((a, b) => a.time.compareTo(b.time));
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// 获取指定类型的提醒列表
  List<Reminder> _getRemindersByType(String type) {
    return _reminders.where((r) => r.type == type).toList();
  }

  /// 切换提醒启用状态
  Future<void> _toggleReminder(Reminder reminder) async {
    reminder.enabled = !reminder.enabled;
    await _reminderRepo.updateReminder(reminder);
    if (reminder.enabled) {
      await _notificationHelper.scheduleReminder(reminder);
    } else {
      await _notificationHelper.cancelReminder(reminder.id);
    }
    _loadData();
    _showSnackBar(reminder.enabled ? '已启用' : '已停用');
  }

  /// 删除提醒
  Future<void> _deleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确定要删除提醒"${reminder.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('删除', style: TextStyle(color: AppColors.textLight)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationHelper.cancelReminder(reminder.id);
      await _reminderRepo.deleteReminder(reminder.id);
      _loadData();
      _showSnackBar('已删除');
    }
  }

  /// 显示添加/编辑提醒弹窗
  void _showReminderDialog({Reminder? existing}) {
    String selectedType = existing?.type ?? ReminderConstants.types[0];
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');
    TimeOfDay selectedTime = _parseTime(existing?.time ?? '08:00');
    List<bool> selectedDays = _parseRepeatRule(existing?.repeatRule ?? '每天');
    bool isEnabled = existing?.enabled ?? true;
    bool isEditing = existing != null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final screenWidth = MediaQuery.of(context).size.width;
            final fontSize = MediaQuery.of(context).textScaler.scale(14);
            final padding = screenWidth * 0.04;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? '编辑提醒' : '添加提醒',
                style: TextStyle(fontSize: fontSize * 1.3),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 提醒类型选择
                    Text('提醒类型', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                    SizedBox(height: padding * 0.5),
                    Wrap(
                      spacing: padding * 0.5,
                      runSpacing: padding * 0.3,
                      children: ReminderConstants.types.map((type) {
                        final isSelected = selectedType == type;
                        return ChoiceChip(
                          label: Text(type, style: TextStyle(fontSize: fontSize * 0.9)),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                selectedType = type;
                                titleController.text = ReminderConstants.defaultTitles[type] ?? '';
                                contentController.text = ReminderConstants.defaultContents[type] ?? '';
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: padding),

                    // 自定义标题
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: '提醒标题',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: padding),

                    // 提醒内容
                    TextField(
                      controller: contentController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '提醒内容',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: padding),

                    // 时间选择
                    Text('提醒时间', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                    SizedBox(height: padding * 0.5),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                alwaysUse24HourFormat: true,
                              ),
                              child: child ?? const SizedBox.shrink(),
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: AppColors.primary, size: fontSize * 1.3),
                            SizedBox(width: padding * 0.5),
                            Text(
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: fontSize * 1.3,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: padding),

                    // 重复周期
                    Text('重复周期', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                    SizedBox(height: padding * 0.5),
                    Wrap(
                      spacing: padding * 0.3,
                      runSpacing: padding * 0.3,
                      children: List.generate(7, (index) {
                        return FilterChip(
                          label: Text(
                            ReminderConstants.weekdays[index],
                            style: TextStyle(fontSize: fontSize * 0.85),
                          ),
                          selected: selectedDays[index],
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          onSelected: (selected) {
                            setDialogState(() => selectedDays[index] = selected);
                          },
                        );
                      }),
                    ),
                    SizedBox(height: padding * 0.5),
                    // 快捷选择
                    Wrap(
                      spacing: padding * 0.3,
                      children: [
                        ActionChip(
                          label: Text('每天', style: TextStyle(fontSize: fontSize * 0.85)),
                          onPressed: () {
                            setDialogState(() {
                              for (int i = 0; i < 7; i++) {
                                selectedDays[i] = true;
                              }
                            });
                          },
                        ),
                        ActionChip(
                          label: Text('工作日', style: TextStyle(fontSize: fontSize * 0.85)),
                          onPressed: () {
                            setDialogState(() {
                              for (int i = 0; i < 7; i++) {
                                selectedDays[i] = i < 5;
                              }
                            });
                          },
                        ),
                        ActionChip(
                          label: Text('周末', style: TextStyle(fontSize: fontSize * 0.85)),
                          onPressed: () {
                            setDialogState(() {
                              for (int i = 0; i < 7; i++) {
                                selectedDays[i] = i >= 5;
                              }
                            });
                          },
                        ),
                        ActionChip(
                          label: Text('清除', style: TextStyle(fontSize: fontSize * 0.85)),
                          onPressed: () {
                            setDialogState(() {
                              for (int i = 0; i < 7; i++) {
                                selectedDays[i] = false;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: padding),

                    // 启用开关
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('启用提醒', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                        Switch(
                          value: isEnabled,
                          onChanged: (v) => setDialogState(() => isEnabled = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('取消', style: TextStyle(fontSize: fontSize)),
                ),
                ElevatedButton(
                  onPressed: () => _saveReminder(
                    existing: existing,
                    type: selectedType,
                    title: titleController.text,
                    content: contentController.text,
                    time: selectedTime,
                    selectedDays: selectedDays,
                    enabled: isEnabled,
                    dialogContext: ctx,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                  ),
                  child: Text(isEditing ? '保存' : '添加', style: TextStyle(fontSize: fontSize)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 保存提醒
  Future<void> _saveReminder({
    Reminder? existing,
    required String type,
    required String title,
    required String content,
    required TimeOfDay time,
    required List<bool> selectedDays,
    required bool enabled,
    required BuildContext dialogContext,
  }) async {
    if (title.trim().isEmpty) {
      _showSnackBar('请输入提醒标题', isError: true);
      return;
    }

    final hasDay = selectedDays.any((d) => d);
    if (!hasDay) {
      _showSnackBar('请至少选择一天', isError: true);
      return;
    }

    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final repeatRule = _buildRepeatRule(selectedDays);
    final defaultContent = content.trim().isEmpty ? ReminderConstants.defaultContents[type] ?? '' : content.trim();

    Reminder savedReminder;
    if (existing != null) {
      existing.type = type;
      existing.title = title.trim();
      existing.content = defaultContent;
      existing.time = timeStr;
      existing.repeatRule = repeatRule;
      existing.enabled = enabled;
      await _reminderRepo.updateReminder(existing);
      savedReminder = existing;
    } else {
      savedReminder = Reminder(
        id: const Uuid().v4(),
        type: type,
        title: title.trim(),
        content: defaultContent,
        time: timeStr,
        repeatRule: repeatRule,
        enabled: enabled,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _reminderRepo.addReminder(savedReminder);
    }

    // 安排系统通知（非Web端）
    if (enabled && !kIsWeb) {
      await _notificationHelper.scheduleReminder(savedReminder);
    }

    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }
    _loadData();
    _showSnackBar(existing != null ? '已更新' : '已添加');
  }

  /// 解析时间为TimeOfDay
  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  /// 解析重复规则为7天选中状态
  List<bool> _parseRepeatRule(String rule) {
    final days = List<bool>.filled(7, false);
    
    if (rule == '每天') {
      for (int i = 0; i < 7; i++) {
        days[i] = true;
      }
      return days;
    }
    if (rule == '工作日') {
      for (int i = 0; i < 5; i++) {
        days[i] = true;
      }
      return days;
    }
    if (rule == '周末') {
      days[5] = true;
      days[6] = true;
      return days;
    }

    // 解析自定义 "周一,周三,周五" 格式
    final parts = rule.split(',');
    for (final part in parts) {
      final index = ReminderConstants.weekdays.indexOf(part.trim());
      if (index >= 0) {
        days[index] = true;
      }
    }
    return days;
  }

  /// 构建重复规则字符串
  String _buildRepeatRule(List<bool> days) {
    final selected = <String>[];
    for (int i = 0; i < 7; i++) {
      if (days[i]) {
        selected.add(ReminderConstants.weekdays[i]);
      }
    }
    
    if (selected.length == 7) return '每天';
    if (selected.length == 5 && !days[5] && !days[6]) return '工作日';
    if (selected.length == 2 && days[5] && days[6]) return '周末';
    
    return selected.join(',');
  }

  /// 获取图标
  IconData _getTypeIcon(String type) {
    switch (type) {
      case '健身训练':
        return Icons.fitness_center;
      case '喝水':
        return Icons.water_drop;
      case '测血压':
        return Icons.monitor_heart;
      case '服药':
        return Icons.medication;
      default:
        return Icons.notifications;
    }
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04;
    final fontSize = MediaQuery.of(context).textScaler.scale(14);

    return Scaffold(
      appBar: AppBar(
        title: const Text('提醒管理'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kIsWeb) _buildWebNotice(context, padding, fontSize),
                  ...ReminderConstants.types.map((type) {
                    final typeReminders = _getRemindersByType(type);
                    return Padding(
                      padding: EdgeInsets.only(bottom: padding),
                      child: _buildTypeSection(context, type, typeReminders, padding, fontSize),
                    );
                  }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReminderDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.textLight),
        label: Text(
          '添加提醒',
          style: TextStyle(color: AppColors.textLight, fontSize: fontSize),
        ),
      ),
    );
  }

  /// 构建Web端提示
  Widget _buildWebNotice(BuildContext context, double padding, double fontSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      margin: EdgeInsets.only(bottom: padding),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: fontSize * 1.3),
          SizedBox(width: padding),
          Expanded(
            child: Text(
              '桌面/移动端支持系统定时提醒，Web端已降级为页面内提醒',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: fontSize * 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建类型分组
  Widget _buildTypeSection(
    BuildContext context,
    String type,
    List<Reminder> reminders,
    double padding,
    double fontSize,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getTypeIcon(type), color: AppColors.primary, size: fontSize * 1.4),
                SizedBox(width: padding * 0.5),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: fontSize * 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 0.5,
                    vertical: padding * 0.15,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${reminders.where((r) => r.enabled).length}/${reminders.length}',
                    style: TextStyle(fontSize: fontSize * 0.85, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            if (reminders.isEmpty) ...[
              SizedBox(height: padding),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Text(
                    '暂无$type提醒',
                    style: TextStyle(fontSize: fontSize, color: AppColors.textHint),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(height: padding * 0.5),
              ...reminders.map((r) => _buildReminderCard(context, r, padding, fontSize)),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建提醒卡片
  Widget _buildReminderCard(BuildContext context, Reminder reminder, double padding, double fontSize) {
    return Container(
      margin: EdgeInsets.only(bottom: padding * 0.5),
      decoration: BoxDecoration(
        color: reminder.enabled
            ? AppColors.surface
            : AppColors.textHint.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reminder.enabled
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.divider,
        ),
      ),
      child: InkWell(
        onTap: () => _showReminderDialog(existing: reminder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(padding * 0.8),
          child: Row(
            children: [
              // 时间显示
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.time,
                    style: TextStyle(
                      fontSize: fontSize * 1.4,
                      fontWeight: FontWeight.bold,
                      color: reminder.enabled ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                  SizedBox(height: padding * 0.1),
                  Text(
                    reminder.repeatRule,
                    style: TextStyle(
                      fontSize: fontSize * 0.85,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(width: padding),
              // 标题和内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: reminder.enabled ? AppColors.textPrimary : AppColors.textHint,
                      ),
                    ),
                    SizedBox(height: padding * 0.1),
                    Text(
                      reminder.content,
                      style: TextStyle(
                        fontSize: fontSize * 0.85,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 操作按钮
              Switch(
                value: reminder.enabled,
                onChanged: (v) => _toggleReminder(reminder),
              ),
              IconButton(
                onPressed: () => _deleteReminder(reminder),
                icon: Icon(Icons.delete_outline, color: AppColors.textHint, size: fontSize * 1.2),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
