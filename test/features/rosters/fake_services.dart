import 'dart:typed_data';

import 'package:bessie/src/services/assignment_service.dart';
import 'package:bessie/src/services/file_service.dart';
import 'package:bessie/src/shared/services/popup_service.dart';
import 'package:bessie/src/shared/services/toast.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers confirmations from a script and remembers toasts.
class FakePopupService extends PopupService {
  bool confirmAnswer = true;
  final List<({String? title, String? message})> confirmations = [];
  final List<({ToastType type, String? message})> toasts = [];

  Iterable<String?> messages(ToastType type) => toasts.where((t) => t.type == type).map((t) => t.message);

  @override
  Future<bool> showConfirmationDialog({String? title, String? message}) async {
    confirmations.add((title: title, message: message));
    return confirmAnswer;
  }

  @override
  Future<T> executeWithSpinner<T>({required String inProgressMessage, String? title, required Future<T> Function() task}) => task();

  @override
  void showToast({String? title, String? message, Widget? action, ToastType type = ToastType.info}) {
    toasts.add((type: type, message: message));
  }
}

class FakeFileService extends FileService {
  Uint8List? picked;
  final List<({String name, String extension, String contents})> saved = [];

  @override
  Future<Uint8List?> pickCsv() async => picked;

  @override
  Future<void> saveText({required String name, required String extension, required String contents, required MimeType mimeType}) async {
    saved.add((name: name, extension: extension, contents: contents));
  }
}

/// Records how the engine would have been run, whatever its signature.
class FakeAssignmentService extends Fake implements AssignmentService {
  final List<({String sessionId, Set<String>? camperIds, Set<String>? blockIds})> runs = [];
  AssignmentRunReport report = const AssignmentRunReport(
    assignedCount: 5,
    placementCount: 5,
    stalemates: [],
    evaluationReports: [],
    stepReports: [],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #run) {
      runs.add((
        sessionId: invocation.namedArguments[#sessionId] as String,
        camperIds: invocation.namedArguments[#camperIds] as Set<String>?,
        blockIds: invocation.namedArguments[#blockIds] as Set<String>?,
      ));
      return Future.value(report);
    }
    return super.noSuchMethod(invocation);
  }
}
