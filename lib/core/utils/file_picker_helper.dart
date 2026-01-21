import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FilePickerHelper {
  static Future<List<File>> pickFiles({
    bool allowMultiple = true,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      withData: false,
    );

    if (result == null) return [];

    return result.paths
        .whereType<String>()
        .map((path) => File(path))
        .toList();
  }
}