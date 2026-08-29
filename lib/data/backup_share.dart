import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import 'backup.dart';

Future<T> _openPicker<T>(Future<T> Function() action) async {
  try {
    await FilePicker.clearTemporaryFiles();
  } catch (_) {}
  try {
    return await action();
  } on PlatformException catch (error) {
    if (error.code != 'already_active' && error.code != 'multiple_request') {
      rethrow;
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    try {
      await FilePicker.clearTemporaryFiles();
    } catch (_) {}
    return action();
  }
}

/// Opens the system save dialog. Returns false if the user cancelled.
Future<bool> saveBackup(BackupSnapshot snapshot) async {
  final uri = await _openPicker(
    () => FilePicker.saveFile(
      fileName: snapshot.fileName,
      bytes: Uint8List.fromList(utf8.encode(snapshot.encode())),
      mimeType: 'application/json',
      dialogTitle: snapshot.fileName,
    ),
  );
  return uri != null;
}

/// Opens the system file picker. Returns null if the user cancelled.
Future<BackupSnapshot?> pickBackup() async {
  final file = await _openPicker(
    () => FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    ),
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
