import 'dart:convert';
import 'package:pointycastle/digests/sha256.dart';

/// 密码加密工具
///
/// 使用 pointycastle 的 SHA256 对4位数字密码进行加盐哈希存储，
/// 避免明文存储。盐值与 App 绑定，提升安全性。
class PasswordUtil {
  /// 加密盐值（与 App 绑定，不随用户变化）
  static const String _salt = 'yanji_2024_security_salt_v1';

  /// 对明文密码进行 SHA256 哈希
  ///
  /// [password] 4位数字明文密码
  /// 返回 64 位十六进制字符串
  static String hashPassword(String password) {
    final digest = SHA256Digest();
    final bytes = utf8.encode('$password$_salt');
    final hash = digest.process(bytes);
    return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 验证密码是否匹配
  ///
  /// [password] 用户输入的明文密码
  /// [hashedPassword] 存储的哈希密码
  /// 返回是否匹配
  static bool verifyPassword(String password, String? hashedPassword) {
    if (hashedPassword == null || hashedPassword.isEmpty) return false;
    return hashPassword(password) == hashedPassword;
  }
}
