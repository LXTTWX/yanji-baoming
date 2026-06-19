import 'package:hive/hive.dart';
import 'package:yanji/core/constants/app_constants.dart';
import 'package:yanji/data/models/user_profile.dart';

/// 用户资料仓库
class UserProfileRepository {
  Box<UserProfile>? _box;

  /// 获取Hive盒子
  Future<Box<UserProfile>> _getBox() async {
    _box ??= await Hive.openBox<UserProfile>(AppConstants.boxUserProfile);
    return _box!;
  }

  /// 获取用户资料
  Future<UserProfile?> getProfile() async {
    final box = await _getBox();
    return box.get(AppConstants.demoUserId);
  }

  /// 保存用户资料
  Future<void> saveProfile(UserProfile profile) async {
    final box = await _getBox();
    await box.put(profile.id, profile);
  }

  /// 更新用户资料
  Future<void> updateProfile(UserProfile profile) async {
    profile.updatedAt = DateTime.now().toIso8601String();
    await saveProfile(profile);
  }

  /// 初始化演示数据
  Future<void> initDemoData() async {
    final box = await _getBox();
    if (box.isEmpty) {
      final demo = UserProfile.demo();
      await box.put(demo.id, demo);
    }
  }

  /// 删除用户资料
  Future<void> deleteProfile(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
