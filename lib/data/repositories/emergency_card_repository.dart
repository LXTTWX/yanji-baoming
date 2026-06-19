import 'package:hive/hive.dart';
import 'package:yanji/core/constants/app_constants.dart';
import 'package:yanji/data/models/emergency_card.dart';

/// 急救卡仓库
///
/// 管理两个 Hive Box：
/// - [AppConstants.boxEmergencyCard]：急救卡信息（单例）
/// - [AppConstants.boxEmergencyContact]：紧急联系人列表
class EmergencyCardRepository {
  Box<EmergencyCard>? _cardBox;
  Box<EmergencyContact>? _contactBox;

  /// 获取急救卡 Box
  Future<Box<EmergencyCard>> _getCardBox() async {
    _cardBox ??= await Hive.openBox<EmergencyCard>(AppConstants.boxEmergencyCard);
    return _cardBox!;
  }

  /// 获取紧急联系人 Box
  Future<Box<EmergencyContact>> _getContactBox() async {
    _contactBox ??=
        await Hive.openBox<EmergencyContact>(AppConstants.boxEmergencyContact);
    return _contactBox!;
  }

  // ==================== 急救卡信息 ====================

  /// 获取急救卡信息（不存在则创建默认）
  Future<EmergencyCard> getCard() async {
    final box = await _getCardBox();
    var card = box.get('emergency_card_main');
    if (card == null) {
      card = EmergencyCard.defaultCard();
      await box.put('emergency_card_main', card);
    }
    return card;
  }

  /// 保存急救卡信息
  Future<void> saveCard(EmergencyCard card) async {
    final box = await _getCardBox();
    card.updatedAt = DateTime.now().toIso8601String();
    await box.put('emergency_card_main', card);
  }

  // ==================== 紧急联系人 ====================

  /// 获取所有紧急联系人（第一联系人置顶）
  Future<List<EmergencyContact>> getAllContacts() async {
    final box = await _getContactBox();
    final list = box.values.toList();
    list.sort((a, b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  /// 获取第一紧急联系人
  Future<EmergencyContact?> getPrimaryContact() async {
    final contacts = await getAllContacts();
    for (final c in contacts) {
      if (c.isPrimary) return c;
    }
    return contacts.isNotEmpty ? contacts.first : null;
  }

  /// 添加紧急联系人
  Future<void> addContact(EmergencyContact contact) async {
    final box = await _getContactBox();
    // 如果新增的是第一联系人，先把其他人的 isPrimary 置为 false
    if (contact.isPrimary) {
      await _clearOtherPrimary(box);
    }
    await box.put(contact.id, contact);
  }

  /// 更新紧急联系人
  Future<void> updateContact(EmergencyContact contact) async {
    final box = await _getContactBox();
    if (contact.isPrimary) {
      await _clearOtherPrimary(box, excludeId: contact.id);
    }
    await box.put(contact.id, contact);
  }

  /// 删除紧急联系人
  Future<void> deleteContact(String id) async {
    final box = await _getContactBox();
    await box.delete(id);
  }

  /// 清除其他联系人的第一联系人标记
  Future<void> _clearOtherPrimary(Box<EmergencyContact> box,
      {String? excludeId}) async {
    for (final contact in box.values) {
      if (excludeId != null && contact.id == excludeId) continue;
      if (contact.isPrimary) {
        contact.isPrimary = false;
        await box.put(contact.id, contact);
      }
    }
  }

  // ==================== 演示数据 ====================

  /// 初始化演示数据
  Future<void> initDemoData() async {
    final cardBox = await _getCardBox();
    if (cardBox.isEmpty) {
      final card = EmergencyCard(
        id: 'emergency_card_main',
        bloodType: 1, // A型
        allergies: '青霉素\n海鲜',
        organDonor: 1, // 愿意
        preferredLanguage: '普通话',
        medicalNotes: '高血压病史5年，长期服用降压药',
        updatedAt: DateTime.now().toIso8601String(),
      );
      await cardBox.put('emergency_card_main', card);
    }

    final contactBox = await _getContactBox();
    if (contactBox.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final demoContacts = [
        EmergencyContact(
          id: 'demo_contact_1',
          name: '李明',
          relationship: '儿子',
          phone: '13800138001',
          isPrimary: true,
          note: '知道我的用药情况',
          createdAt: now,
        ),
        EmergencyContact(
          id: 'demo_contact_2',
          name: '王医生',
          relationship: '家庭医生',
          phone: '13900139002',
          isPrimary: false,
          note: '社区医院全科医生',
          createdAt: now,
        ),
      ];
      for (final contact in demoContacts) {
        await contactBox.put(contact.id, contact);
      }
    }
  }
}
