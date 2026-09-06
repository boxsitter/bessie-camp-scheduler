import 'package:bessie/src/shared/widgets/context_switcher/controller/session_selector_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/services/popup_service.dart';
import '../../../shared/theme/shad_theme.dart';

Future<dynamic> showContextSwitcher() {
  // Initialize the controller when the dialog is shown.
  // GetX will handle its lifecycle.
  final controller = Get.find<SessionSelectorController>();

  return Get.find<PopupService>().showFullScreenDialog(
    title: 'Change active session',
    description: 'Any unsaved changes or data will be discarded',
    // Actions are now wrapped in an Obx to be reactive
    actions: [
      Obx(
            () => ShadButton(
          // The button's onPressed is now connected to the controller.
          // It's disabled if no session is selected.
          onPressed: controller.selectedSessionKey.value == null
              ? null
              : controller.migrateToSelectedContext,
          child: const Text('Switch'),
        ),
      ),
    ],
    child: Container(
      width: 375,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Session',
            textAlign: TextAlign.end,
            style: BessShadTheme.shadThemeData.textTheme.small,
          ),
          const SizedBox(width: 16),
          // The dropdown area is now reactive
          Obx(
                () {
              // Show a loading indicator while fetching data
              if (controller.isLoading.value) {
                return const SizedBox(
                  width: 180,
                  child: Center(child: ShadProgress()),
                );
              }
              // Once loaded, show the dropdown with data from the controller
              return SessionSelectWithSearch(
                sessions: controller.sessions.value,
                selectedValue: controller.selectedSessionKey.value,
                onChanged: controller.updateSelection,
              );
            },
          ),
        ],
      ),
    ),
  );
}

class SessionSelectWithSearch extends StatefulWidget {
  const SessionSelectWithSearch({
    super.key,
    required this.sessions,
    this.selectedValue,
    this.onChanged,
  });

  // These values are now provided by the parent widget
  final Map<String, String> sessions;
  final String? selectedValue;
  final ValueChanged<String?>? onChanged;

  @override
  State<SessionSelectWithSearch> createState() =>
      _SessionSelectWithSearchState();
}

class _SessionSelectWithSearchState extends State<SessionSelectWithSearch> {
  var searchValue = '';

  Map<String, String> get filteredSessions => {
    for (final session in widget.sessions.entries)
      if (session.value.toLowerCase().contains(searchValue.toLowerCase()))
        session.key: session.value
  };

  @override
  Widget build(BuildContext context) {
    return ShadSelect<String>.withSearch(
      minWidth: 180,
      maxWidth: 300,
      initialValue: widget.selectedValue, // Use the passed-in value
      onChanged: widget.onChanged, // Use the passed-in callback
      placeholder: const Text('Select session...'),
      onSearchChanged: (value) => setState(() => searchValue = value),
      searchPlaceholder: const Text('Search session'),
      options: [
        if (filteredSessions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No session found'),
          ),
        ...widget.sessions.entries.map(
              (session) {
            return Offstage(
              offstage: !filteredSessions.containsKey(session.key),
              child: ShadOption(
                value: session.key,
                child: Text(session.value),
              ),
            );
          },
        )
      ],
      selectedOptionBuilder: (context, value) {
        // Look up the name from the passed-in sessions map
        return Text(widget.sessions[value] ?? '');
      },
    );
  }
}