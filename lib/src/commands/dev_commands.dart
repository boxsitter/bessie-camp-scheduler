
import 'package:bessie/src/cli/cli.dart';
import 'package:bessie/src/services/database_repair_service.dart';
import 'package:get/get.dart';

import '../ember_core.dart';

class DevCommands {
  static Map<String, EmberCommand> list = {
    'rstact': ResetActivityAssignments(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
    'bka': BackupActivityAssignments(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
    'clractdep': ClearActivityDependents(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
  };
}

class ResetActivityAssignments extends EmberCommand {
  final DatabaseRepairService repairService = Get.find<DatabaseRepairService>();
  final CommitRepository commitRepo = Get.find<CommitRepository>();

  @override
  final String name = 'rstact';
  @override
  final String description = 'Resets all activity assignments';
  @override
  String get invocationDetails => 'rstact';
  @override
  List<String> get examples => ['rstact'];

  ResetActivityAssignments({required super.userInput, required super.userOutput});

  @override
  Future<dynamic> run() async {
    Commit commit = Commit(disarmRequirementsLevel: 0);
    try {
      await repairService.resetAllAssignmentsAndPreferences(commit: commit);
      await commitRepo.commit(commit);
    } on Exception catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    }
    userOutput.log('Activity assignments have been reset!');
  }
}

class BackupActivityAssignments extends EmberCommand {
  final ScheduleService scheduleService = Get.find<ScheduleService>();
  final RosterService rosterService = Get.find<RosterService>();
  final IOService exportService = Get.find<IOService>();

  @override
  final String name = 'bka';
  @override
  final String description = 'Backs up activity assignments to a JSON file.';
  @override
  String get invocationDetails => 'bka';
  @override
  List<String> get examples => ['bka'];

  BackupActivityAssignments({required super.userInput, required super.userOutput});

  @override
  Future<void> run() async {
    // FIX: Filter out any potential null values from the list of blocks.
    final allBlocks = (await scheduleService.amas).whereType<AMABlock>().toList();

    if (allBlocks.isEmpty) {
      userOutput.error('No AMA blocks found to back up.');
      return;
    }

    final List<FormFieldDescriptor> formFields = [
      MultiSelectFormFieldDescriptor<AMABlock>(
        label: 'Select AMA Blocks to Backup',
        options: allBlocks,
        optionLabelBuilder: (value) => value == null ? '' : (value as AMABlock).displayTitle,
        isRequired: true,
      ),
      BooleanFormFieldDescriptor(label: 'Separate file for each block?'),
    ];

    final promptOutput = await userInput.promptForm('Backup Activity Assignments', formFields);
    if (promptOutput == null) {
      userOutput.info('Backup cancelled.');
      return;
    }

    final List<AMABlock> selectedBlocks = (promptOutput[0] as List?)?.cast<AMABlock>() ?? [];
    final bool separateFiles = promptOutput[1] as bool;

    if (selectedBlocks.isEmpty) {
      userOutput.info('No blocks selected. Nothing to back up.');
      return;
    }

    final allCampers = (await rosterService.registeredCampers).values;
    final Map<String, Map<String, String>> backupData = {};

    for (final block in selectedBlocks) {
      final Map<String, String> blockAssignments = {};
      for (final camper in allCampers) {
        final assignedActivityId = camper.activityAssignmentRefs[block.id];
        if (assignedActivityId != null) {
          blockAssignments[camper.id] = assignedActivityId;
        }
      }
      backupData[block.id] = blockAssignments;
    }

    final savedFiles = await exportService.backupAssignments(
      backupData: backupData,
      selectedBlocks: selectedBlocks,
      separateFiles: separateFiles,
    );

    if (savedFiles.isNotEmpty) {
      userOutput.success('Successfully created ${savedFiles.length} backup file(s).');
      for (final path in savedFiles) {
        userOutput.log('  - $path');
      }
    } else {
      userOutput.info('Backup operation was cancelled. No files were saved.');
    }
  }
}

class ClearActivityDependents extends EmberCommand {
  final ScheduleService scheduleService = Get.find<ScheduleService>();
  final CommitRepository commitRepo = Get.find<CommitRepository>();

  @override
  final String name = 'clractdep';
  @override
  final String description = 'Clears camper references from all activity dependents.';
  @override
  String get invocationDetails => 'clractdep';
  @override
  List<String> get examples => ['clractdep'];

  ClearActivityDependents({required super.userInput, required super.userOutput});

  @override
  Future<dynamic> run() async {
    Commit commit = Commit(disarmRequirementsLevel: 0);
    try {
      final Set<ActivityDependent> allActivityDependents = await scheduleService.activityDependents;
      for (var dependent in allActivityDependents) {
        dependent.camperRefs.clear();
        commit.addObjectToPush(dependent);
      }
      await commitRepo.commit(commit);
      userOutput.log('All activity dependents have been cleared.');
    } on Exception catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    }
  }
}