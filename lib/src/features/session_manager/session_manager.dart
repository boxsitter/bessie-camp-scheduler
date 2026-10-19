import 'package:flutter/material.dart';

import '../../shared/widgets/header/menu_bar.dart';
import '../../shared/widgets/layouts/templates/site_layout.dart';
import 'session_manager_view.dart';

/// Session setup: cabins, preference limits and schedule of the current
/// session, and creating new sessions.
class SessionManager extends StatelessWidget {
  const SessionManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BessSiteTemplate(desktop: const SessionManagerView(), menuBar: BessMenuBar());
  }
}
