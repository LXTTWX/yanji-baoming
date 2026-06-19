import 'package:hive/hive.dart';
import 'package:yanji/core/constants/app_constants.dart';
import 'package:yanji/data/models/family_member.dart';

/// 家庭成员仓库
class FamilyMemberRepository {
  Box<FamilyMember>? _box;

  /// 获取Hive盒子
  Future<Box<FamilyMember>> _getBox() async {
    _box ??= await Hive.openBox<FamilyMember>(AppConstants.boxFamilyMember);
    return _box!;
  }

  /// 获取所有家庭成员
  Future<List<FamilyMember>> getAllMembers() async {
    final box = await _getBox();
    return box.values.toList();
  }

  /// 根据ID获取成员
  Future<FamilyMember?> getMemberById(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  /// 添加家庭成员
  Future<void> addMember(FamilyMember member) async {
    final box = await _getBox();
    await box.put(member.id, member);
  }

  /// 更新家庭成员
  Future<void> updateMember(FamilyMember member) async {
    final box = await _getBox();
    await box.put(member.id, member);
  }

  /// 删除家庭成员
  Future<void> deleteMember(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  /// 初始化演示数据
  Future<void> initDemoData() async {
    final box = await _getBox();
    if (box.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final demoMembers = [
        FamilyMember(
          id: 'demo_member_1',
          name: '爸爸',
          relationship: '父亲',
          age: 58,
          gender: 1,
          phone: '13800138001',
          createdAt: now,
        ),
        FamilyMember(
          id: 'demo_member_2',
          name: '妈妈',
          relationship: '母亲',
          age: 55,
          gender: 2,
          phone: '13800138002',
          createdAt: now,
        ),
      ];
      for (final member in demoMembers) {
        await box.put(member.id, member);
      }
    }
  }
}
