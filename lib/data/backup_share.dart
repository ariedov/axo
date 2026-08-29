import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'backup.dart';

/// Opens the system save dialog. Returns false if the user cancelled.
Future<bool> saveBackup(BackupSnapshot snapshot) async {
  final uri = await FilePicker.saveFile(
    fileName: snapshot.fileName,
    bytes: Uint8List.fromList(utf8.encode(snapshot.encode())),
    mimeType: 'application/json',
    dialogTitle: snapshot.fileName,
  );
  return uri != null;
}

/// Opens the system file picker. Returns null if the user cancelled.
Future<BackupSnapshot?> pickBackup() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['json'],
  );
  if (file == null) return null;
  try {
    final decoded = jsonDecode(utf8.decode(await file.readAsBytes()));
    if (decoded is! Map) {
      throw const FormatException('not an Axo backup');
    }
    return BackupSnapshot.fromJson(Map<String, dynamic>.from(decoded));
  } on FormatException {
    rethrow;
  } catch (_) {
    throw const FormatException('not an Axo backup');
  }
}
