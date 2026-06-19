import 'dart:io';

/// 原生端导出文件到临时目录
Future<String?> exportToTempFile(String content, String fileName) async {
  try {
    final directory = Directory('${Platform.environment['USERPROFILE']}\\Documents');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    final file = File('${directory.path}\\$fileName');
    await file.writeAsString(content);
    return file.path;
  } catch (_) {
    return null;
  }
}

/// 原生端读取文件内容
Future<String?> readFileContent(String path) async {
  try {
    final file = File(path);
    return await file.readAsString();
  } catch (_) {
    return null;
  }
}
