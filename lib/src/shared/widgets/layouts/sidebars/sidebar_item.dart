import 'package:flutter/widgets.dart';

import '../../../routes/routes.dart';

/// One entry of the sidebar.
class SidebarItem {
  const SidebarItem({required this.route, required this.title, required this.icon});

  final String route;
  final String title;
  final IconData icon;

  /// Only directors and admins get this item (it leads to a writers-only route).
  bool get writersOnly => BessRoutes.writerOnlyRoutes.contains(route);
}
