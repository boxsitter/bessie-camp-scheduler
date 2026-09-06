import 'dart:async';

import 'package:bessie/src/cli/cli.dart';
import 'package:get/get.dart';

import '../ember_core.dart';

class SetupCommands {
  static Map<String, EmberCommand> list = {
    'con': ViewContext(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
    'brns': ListBranches(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
    'seas': ListSeasons(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
    'sess': ListSessions(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
    'migcon': MigrateContext(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
    'mksesh': MakeSession(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
    'mkweek': MakeWeek(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
    'addact': AddActivities(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
    'rmact': RemoveActivities(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
  };
}

///  extends EmberCommand to view the current client context.
class ViewContext extends EmberCommand {
  @override
  final String name = 'con';
  @override
  final String description = 'Displays the current client context (organization, branch, season, session).';
  @override
  String get invocationDetails => 'con';
  @override
  List<String> get examples => ['con'];

  ViewContext({required super.userInput, required super.userOutput});

  @override
  FutureOr<void> run() {
    // TODO: Implement run method
    // 1. Get current context from ClientContextService.
    // 2. Format and display the context details using userOutput.
    userOutput.info('ViewContext extends EmberCommand run: Not yet implemented.');
    userOutput.printProperty('Current Organization', 'TODO');
    userOutput.printProperty('Current Branch', 'TODO');
    userOutput.printProperty('Current Season', 'TODO');
    userOutput.printProperty('Current Session', 'TODO');
  }
}

///  extends EmberCommand to list available branches within the current/specified organization.
class ListBranches extends EmberCommand {
  @override
  final String name = 'brns';
  @override
  final String description = 'Lists available branches for the current or a specified organization.';
  @override
  String get invocationDetails => 'brns';
  @override
  List<String> get examples => ['brns'];

  ListBranches({
    required super.userInput,
    required super.userOutput,
    // required ClientContextService clientContextService
  });

  @override
  FutureOr<void> run() {
    // TODO: Implement run method
    // 1. Get orgId from args or current context.
    // 2. Fetch branches for that org.
    // 3. Display them.
    userOutput.info('ListBranches extends EmberCommand run: Not yet implemented.');
  }
}

// Similar commands would follow for Season and Session:
// - `season list [--branchId <branchId>]`
// - `season set <seasonId>`
// - `session list [--seasonId <seasonId>]`
// - `session set <sessionId>`

///  extends EmberCommand to list available seasons for the current/specified branch.
class ListSeasons extends EmberCommand {
  @override
  final String name = 'seas';
  @override
  final String description = 'Lists available seasons for the current or a specified branch.';
  @override
  String get invocationDetails => 'seas';
  @override
  List<String> get examples => ['seas'];

  ListSeasons({required super.userInput, required super.userOutput});

  @override
  FutureOr<void> run() {
    userOutput.info('ListSeasons extends EmberCommand run: Not yet implemented.');
  }
}

///  extends EmberCommand to list available sessions for the current/specified season.
class ListSessions extends EmberCommand {
  @override
  final String name = 'sess';
  @override
  final String description = 'Lists available sessions for the current or a specified season.';
  @override
  String get invocationDetails => 'sess';
  @override
  List<String> get examples => ['sess'];

  ListSessions({required super.userInput, required super.userOutput});

  @override
  FutureOr<void> run() {
    userOutput.info('ListSessions extends EmberCommand run: Not yet implemented.');
  }
}

///  extends EmberCommand to list available sessions for the current/specified season.
class MigrateContext extends EmberCommand {
  @override
  final String name = 'migcon';
  @override
  final String description = 'Attempts to migrate the user to a new context';
  @override
  String get invocationDetails => 'migcon';
  @override
  List<String> get examples => ['migcon'];

  MigrateContext({required super.userInput, required super.userOutput});

  @override
  FutureOr<void> run() {
    userOutput.info('Attempts to migrate the user to a new context');
  }
}

class MakeSession extends EmberCommand {
  final CommitRepository commitRepo = Get.find<CommitRepository>();
  @override
  final String name = 'mksesh';
  @override
  final String description = '';
  @override
  String get invocationDetails => '';
  @override
  List<String> get examples => [''];

  MakeSession({required super.userInput, required super.userOutput});

  @override
  Future<void> run() async {
    String name = await userInput.prompt('Name: ', allowEmpty: false);
    String date = await userInput.prompt('Date (month/day): ', allowEmpty: false);

    Commit commit = Commit(disarmRequirementsLevel: 0);
    Session newSession = Session(
      name: name,
      start: DateTime.parse('2025-${date.split('/')[0].padLeft(2, '0')}-${date.split('/')[1].padLeft(2, '0')}'),
    );
    commit.addObjectToPush(newSession);
    await commitRepo.commit(commit);
    userOutput.success('Session $name Created!');
  }
}

class MakeDay extends EmberCommand {
  final CommitRepository commitRepo = Get.find<CommitRepository>();
  final ScheduleService scheduleService = Get.find<ScheduleService>();
  @override
  final String name = 'mkday';
  @override
  final String description = '';
  @override
  String get invocationDetails => '';
  @override
  List<String> get examples => [''];

  MakeDay({required super.userInput, required super.userOutput});

  @override
  Future<void> run() async {
    int dayIndex = int.parse(await userInput.prompt('Day Index: ', allowEmpty: false));
    String date = await userInput.prompt('Date (month/day): ', allowEmpty: false);

    Commit commit = Commit(disarmRequirementsLevel: 0);
    ScheduleDay newDay = ScheduleDay(
      dayIndex: dayIndex,
      start: DateTime.parse('2025-${date.split('/')[0].padLeft(2, '0')}-${date.split('/')[1].padLeft(2, '0')}'),
    );
    commit.addObjectToPush(newDay);
    Schedule schedule = await scheduleService.schedule;
    schedule.scheduleDayCmps.add(newDay.id);
    commit.addObjectToPush(schedule);
    await commitRepo.commit(commit);
    userOutput.success('Session $name Created!');
  }
}

class MakeWeek extends EmberCommand {
  final CommitRepository commitRepo = Get.find<CommitRepository>();
  final ScheduleService scheduleService = Get.find<ScheduleService>();
  @override
  final String name = 'mkweek';
  @override
  final String description = '';
  @override
  String get invocationDetails => '';
  @override
  List<String> get examples => [''];

  MakeWeek({required super.userInput, required super.userOutput});

  @override
  Future<void> run() async {
    String startDateString = await userInput.prompt('Start Date (month/day): ', allowEmpty: false);
    DateTime startDate = DateTime.parse(
      '2025-${startDateString.split('/')[0].padLeft(2, '0')}-${startDateString.split('/')[1].padLeft(2, '0')}',
    );
    Commit commit = Commit(disarmRequirementsLevel: 0);
    Schedule ogSchedule = Schedule();
    commit.addObjectToPush(ogSchedule);

    for (int i = 0; i < 5; i++) {
      DateTime currentDay = startDate.add(i.days);
      ScheduleDay newDay = ScheduleDay(dayIndex: i, start: startDate.add(i.days));
      Schedule schedule = commit.getObjectOfType();
      schedule.scheduleDayCmps.add(newDay.id);
      commit.addObjectToPush(newDay);

      final AMABlock choiceActivity1 = AMABlock(
        title: 'Choice Activity 1',
        isTemplate: false,
        start: DateTime(2025, currentDay.month, currentDay.day, 10, 15),
        end: DateTime(2025, currentDay.month, currentDay.day, 11, 15),
        isSkillsRec: false,
      );
      commit.addObjectToPush(choiceActivity1);
      scheduleService.addBlockToDay(commit, newDay.id, choiceActivity1);

      if (i != 4) {
        final AMABlock choiceActivity2 = AMABlock(
          title: 'Choice Activity 2',
          isTemplate: false,
          start: DateTime(2025, currentDay.month, currentDay.day, 11, 20),
          end: DateTime(2025, currentDay.month, currentDay.day, 12, 20),
          isSkillsRec: false,
        );
        commit.addObjectToPush(choiceActivity2);
        scheduleService.addBlockToDay(commit, newDay.id, choiceActivity2);
      }

      if (i == 1) {
        final AMABlock skillsRec = AMABlock(
          title: 'Skills Rec',
          isTemplate: false,
          start: DateTime(2025, currentDay.month, currentDay.day, 9, 15),
          end: DateTime(2025, currentDay.month, currentDay.day, 10, 10),
          isSkillsRec: true,
        );
        commit.addObjectToPush(skillsRec);
        scheduleService.addBlockToDay(commit, newDay.id, skillsRec);
      }
    }

    await commitRepo.commit(commit);
    userOutput.success('Week Created!');
  }
}

class AddActivities extends EmberCommand {
  final CommitRepository commitRepo = Get.find<CommitRepository>();
  final ScheduleService scheduleService = Get.find<ScheduleService>();
  @override
  final String name = 'addact';
  @override
  final String description = '';
  @override
  String get invocationDetails => '';
  @override
  List<String> get examples => [''];

  AddActivities({required super.userInput, required super.userOutput});

  @override
  Future<void> run() async {
    // No changes needed here, this part was already good.
    List<AMABlock> blocks = (await scheduleService.getScheduleBlocks()).values.toSet().whereType<AMABlock>().toList();
    blocks.sort((a, b) => a.start.compareTo(b.start));

    final List<FormFieldDescriptor> formFieldDescriptors1 = [
      SelectFormFieldDescriptor<AMABlock>(
        optionLabelBuilder: (value) => value == null ? '' : (value as AMABlock).displayTitle,
        options: blocks,
        isRequired: true,
        label: 'Activity Periods',
      ),
    ];
    final prompt1Output = (await userInput.promptForm('Select Block', formFieldDescriptors1))?.first;
    if (prompt1Output == null) {
      return;
    }
    AMABlock block = prompt1Output as AMABlock;
    List<PrincipalActivity> activities = (await scheduleService.principalActivities).values.toList();
    List<PrincipalActivity> nonSkills = activities.where((element) => !element.isSkillsRec).toList();
    List<PrincipalActivity> skills = activities.where((element) => element.isSkillsRec).toList();

    final List<FormFieldDescriptor> formFieldDescriptors2 = [
      MultiSelectFormFieldDescriptor<PrincipalActivity>(
        optionLabelBuilder: (value) => value == null ? '' : (value as PrincipalActivity).name,
        options: nonSkills,
        isRequired: false,
        label: 'Standard Choice Activities',
      ),
      MultiSelectFormFieldDescriptor<PrincipalActivity>(
        optionLabelBuilder: (value) => value == null ? '' : (value as PrincipalActivity).name,
        options: skills,
        isRequired: false,
        label: 'Skills Recs',
      ),
    ];
    final prompt2Output = await userInput.promptForm('Select Activities', formFieldDescriptors2);
    if (prompt2Output == null) {
      return;
    }

    final List<PrincipalActivity> selectedNonSkills =
        (prompt2Output[0] as List<dynamic>?)
            ?.map((item) => item as PrincipalActivity)
            .toList() ?? [];

    final List<PrincipalActivity> selectedSkills =
        (prompt2Output[1] as List<dynamic>?)
            ?.map((item) => item as PrincipalActivity)
            .toList() ?? [];

    final List<PrincipalActivity> selectedActivities = [...selectedNonSkills, ...selectedSkills];

    Commit commit = Commit(disarmRequirementsLevel: 0);
    for (PrincipalActivity activity in selectedActivities) {
      await scheduleService.scheduleActivity(commit, activity.id, block.id);
    }

    if (commit.objectsToPush.isEmpty) {
      userOutput.info("No new activities were scheduled.");
      return;
    }

    await commitRepo.commit(commit);
    userOutput.success('Activities scheduled!');
  }
}

class RemoveActivities extends EmberCommand {
  final CommitRepository commitRepo = Get.find<CommitRepository>();
  final ScheduleService scheduleService = Get.find<ScheduleService>();
  @override
  final String name = 'rmact';
  @override
  final String description = '';
  @override
  String get invocationDetails => '';
  @override
  List<String> get examples => [''];

  RemoveActivities({required super.userInput, required super.userOutput});

  @override
  Future<void> run() async {
    List<AMABlock> blocks = (await scheduleService.getScheduleBlocks()).values.toSet().whereType<AMABlock>().toList();
    blocks.sort((a, b) => a.start.compareTo(b.start));

    final List<FormFieldDescriptor> formFieldDescriptors1 = [
      // SIMPLIFICATION: Pass the AMABlock objects directly.
      SelectFormFieldDescriptor<AMABlock>(
        optionLabelBuilder: (value) => value == null ? '' : (value as AMABlock).displayTitle,
        options: blocks,
        isRequired: true,
        label: 'Activity Periods',
      ),
    ];

    final prompt1Output = (await userInput.promptForm('Select Block', formFieldDescriptors1))?.first;
    if (prompt1Output == null) {
      return; // User cancelled.
    }

    // SIMPLIFICATION: The prompt returns the selected object, so no more searching!
    AMABlock block = prompt1Output as AMABlock;
    Set<ActivityDependentId> activityIdsInBlock = block.activityDependentCmps;

    if (activityIdsInBlock.isEmpty) {
      userOutput.info("The selected block has no activities to remove.");
      return;
    }

    final List<FormFieldDescriptor> formFieldDescriptors2 = [
      // SIMPLIFICATION: Pass the PrincipalActivity objects directly.
      MultiSelectFormFieldDescriptor<ActivityDependentId>(
        optionLabelBuilder: (value) => value ?? '',
        options: activityIdsInBlock.toList(),
        isRequired: true,
        label: 'Activities to Remove',
      ),
    ];
    final prompt2Output = await userInput.promptForm('Select Activities To Delete', formFieldDescriptors2);
    if (prompt2Output == null) {
      return; // User cancelled.
    }

    final List<ActivityDependentId> selectedActivities =
        (prompt2Output[0] as List<dynamic>?)
            ?.map((item) => item as ActivityDependentId)
            .toList() ?? [];


    if (selectedActivities.isEmpty) {
      userOutput.info("No activities were selected for removal.");
      return;
    }

    Commit commit = Commit(disarmRequirementsLevel: 0);
    for (ActivityDependentId id in selectedActivities) {
      // We use the ID from the selected object.
      await scheduleService.unScheduleActivity(commit, id);
    }

    await commitRepo.commit(commit);
    userOutput.success('Activities Removed!');
  }
}
