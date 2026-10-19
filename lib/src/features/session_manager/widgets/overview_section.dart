import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../branch_manager/widgets/section_card.dart';
import '../session_setup_logic.dart';

/// The session at a glance: when it starts and how big it is.
class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key, required this.setup, this.seasonName});

  final SessionSetup setup;
  final String? seasonName;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Overview',
      child: Wrap(
        spacing: BessSizes.defaultSpace,
        runSpacing: BessSizes.md,
        children: [
          if (seasonName != null) _Stat(label: 'Season', value: seasonName!),
          _Stat(label: 'Session', value: setup.session.name),
          _Stat(label: 'Starts', value: DateFormat.yMMMEd().format(setup.session.startsOn)),
          _Stat(label: 'Campers', value: '${setup.camperCount}'),
          _Stat(label: 'Blocks', value: '${setup.blockCount}'),
          _Stat(label: 'Cabins', value: '${setup.registeredCabinCount} of ${setup.cabins.length}'),
          _Stat(label: 'Activities scheduled', value: '${setup.scheduledActivityCount}'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 110, maxWidth: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: BessTextStyles.columnHeader),
          const SizedBox(height: BessSizes.xs),
          Text(value, style: BessTextStyles.boldCardTitle.copyWith(letterSpacing: 0), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
