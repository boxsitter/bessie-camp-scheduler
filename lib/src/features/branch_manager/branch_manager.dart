import 'package:flutter/material.dart';

import '../../shared/widgets/header/menu_bar.dart';
import '../../shared/widgets/layouts/templates/site_layout.dart';
import 'branch_manager_view.dart';

/// The catalog of the current branch: its activities and cabins.
class BranchManager extends StatelessWidget {
  const BranchManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BessSiteTemplate(desktop: const BranchManagerView(), menuBar: BessMenuBar());
  }
}
