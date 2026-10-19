import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/colors.dart';
import '../../styles/text_styles.dart';
import 'header_controller.dart';

/// The signed-in user's initials, name and role; opens a menu with Sign out.
class UserMenu extends StatefulWidget {
  const UserMenu({super.key});

  @override
  State<UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends State<UserMenu> {
  final HeaderController _header = Get.find<HeaderController>();
  final ShadPopoverController _popover = ShadPopoverController();

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    _popover.hide();
    await _header.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return ShadPopover(
      controller: _popover,
      popover: (context) => SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_header.displayName, style: BessTextStyles.standardBold),
                    Text(_header.roleTitle, style: BessTextStyles.subtle),
                  ],
                ),
              ),
            ),
            const ShadSeparator.horizontal(margin: EdgeInsets.only(bottom: 4)),
            ShadButton.ghost(
              onPressed: _signOut,
              mainAxisAlignment: MainAxisAlignment.start,
              width: double.infinity,
              leading: const Icon(LucideIcons.logOut, size: 16),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
      child: Obx(
        () => ShadButton.ghost(
          onPressed: _popover.toggle,
          leading: CircleAvatar(
            radius: 15,
            backgroundColor: BessColors.primary,
            child: Text(_header.initials, style: BessTextStyles.standardInverted.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          trailing: const Icon(LucideIcons.chevronDown, size: 16),
          child: Text(_header.displayName),
        ),
      ),
    );
  }
}
