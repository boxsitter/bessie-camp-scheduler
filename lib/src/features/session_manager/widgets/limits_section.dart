import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../branch_manager/widgets/catalog_rows.dart';
import '../../branch_manager/widgets/number_stepper.dart';
import '../../branch_manager/widgets/section_card.dart';
import '../session_setup_logic.dart';

/// How many activities each camper may request and veto.
class LimitsSection extends StatelessWidget {
  const LimitsSection({
    super.key,
    required this.draft,
    required this.saved,
    required this.canEdit,
    required this.busy,
    required this.onChanged,
    required this.onSave,
    required this.onReset,
  });

  /// The values shown, saved or not.
  final LimitsDraft draft;

  /// The values the session has now.
  final LimitsDraft saved;
  final bool canEdit;
  final bool busy;
  final ValueChanged<LimitsDraft> onChanged;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final changed = draft != saved;
    return SectionCard(
      title: 'Preference limits',
      subtitle: 'How many activities a camper may ask for, and rule out, when choosing.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LimitsEditor(draft: draft, onChanged: canEdit ? onChanged : null),
          if (canEdit) ...[
            const SizedBox(height: BessSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton.secondary(onPressed: changed && !busy ? onReset : null, child: const Text('Reset')),
                const SizedBox(width: BessSizes.sm),
                ShadButton(onPressed: changed && !busy ? onSave : null, child: Text(busy ? 'Saving...' : 'Save limits')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The four limits as labelled steppers; read-only when [onChanged] is null.
class LimitsEditor extends StatelessWidget {
  const LimitsEditor({super.key, required this.draft, required this.onChanged});

  final LimitsDraft draft;
  final ValueChanged<LimitsDraft>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    ValueChanged<int>? setter(LimitsDraft Function(int value) update) => onChanged == null ? null : (value) => onChanged(update(value));
    return Column(
      children: [
        _LimitRow(
          label: 'Requests',
          hint: 'Activities a camper can ask for.',
          value: draft.maxRequests,
          onChanged: setter((value) => draft.copyWith(maxRequests: value)),
        ),
        _LimitRow(
          label: 'Vetoes',
          hint: 'Activities a camper can rule out.',
          value: draft.maxVetoes,
          onChanged: setter((value) => draft.copyWith(maxVetoes: value)),
        ),
        _LimitRow(
          label: 'Skills rec requests',
          hint: 'Skills recs a camper can ask for.',
          value: draft.maxSkillsRequests,
          onChanged: setter((value) => draft.copyWith(maxSkillsRequests: value)),
        ),
        _LimitRow(
          label: 'Skills rec vetoes',
          hint: 'Skills recs a camper can rule out.',
          value: draft.maxSkillsVetoes,
          onChanged: setter((value) => draft.copyWith(maxSkillsVetoes: value)),
        ),
      ],
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({required this.label, required this.hint, required this.value, required this.onChanged});

  final String label;
  final String hint;
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CatalogRow(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(label, style: BessTextStyles.standardBold), Text(hint, style: BessTextStyles.standardSecondary)],
      ),
      actions: [NumberStepper(value: value, max: LimitsDraft.highest, onChanged: onChanged)],
    );
  }
}
