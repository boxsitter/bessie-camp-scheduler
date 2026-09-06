import 'package:bessie/src/shared/widgets/header/menu_bar.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/layouts/templates/site_layout.dart';

class BranchManager extends StatelessWidget {
  const BranchManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BessSiteTemplate(desktop: BranchManagerDesktop(), menuBar: BessMenuBar(),);
  }
}

class BranchManagerDesktop extends StatelessWidget {
  const BranchManagerDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox();
  }
}
