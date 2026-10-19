import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../layouts/sidebars/sidebar.dart';
import 'menu_bar.dart';
import 'user_menu.dart';

/// The bar across the top: the page's menu bar on the left (as wide as the
/// sidebar), the page's own actions, and the user menu on the right.
class BessHeader extends StatelessWidget {
  const BessHeader({super.key, required this.menuBar, this.centerActions = const [], this.trailingWidgets = const []});

  static const double height = 55;

  final BessMenuBar menuBar;
  final List<Widget> centerActions;
  final List<Widget> trailingWidgets;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: BessColors.core,
        border: Border(bottom: BorderSide(color: BessColors.semiLow)),
      ),
      child: Row(
        children: [
          Container(
            width: BessSidebar.width,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: BessColors.semiLow)),
            ),
            child: menuBar,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [...centerActions, const Spacer(), ...trailingWidgets, const SizedBox(width: 8), const UserMenu()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
