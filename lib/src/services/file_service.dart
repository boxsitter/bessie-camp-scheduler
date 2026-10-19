import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

/// Picking files to read and saving files for the user.
class FileService {
  const FileService();

  /// Lets the user choose a CSV file; returns its bytes, or null if they cancel.
  Future<Uint8List?> pickCsv() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    return result?.files.firstOrNull?.bytes;
  }

  Future<void> saveText({required String name, required String extension, required String contents, required MimeType mimeType}) async {
    await FileSaver.instance.saveFile(name: name, bytes: Uint8List.fromList(utf8.encode(contents)), ext: extension, mimeType: mimeType);
  }
}
