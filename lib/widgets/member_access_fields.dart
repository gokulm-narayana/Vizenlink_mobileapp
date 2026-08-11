import 'package:flutter/material.dart';

import '../models/member_role.dart';
import '../utils/date_format.dart';

/// Role picker shared by [InviteUserScreen]/[CreateUserScreen] (and
/// previously the Users & Invites dialogs) — a [RadioGroup] of every
/// [MemberRole] with its label and permission description.
class RoleSelectorField extends StatelessWidget {
  const RoleSelectorField({
    super.key,
    required this.role,
    required this.onChanged,
  });

  final MemberRole role;
  final ValueChanged<MemberRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<MemberRole>(
      key: key,
      groupValue: role,
      onChanged: (value) => onChanged(value!),
      child: Column(
        children: [
          for (final r in MemberRole.values)
            RadioListTile<MemberRole>(
              contentPadding: EdgeInsets.zero,
              title: Text(memberRoleLabels[r]!),
              subtitle: Text(memberRoleDescriptions[r]!),
              value: r,
            ),
        ],
      ),
    );
  }
}

/// "Expires" row — opens a date picker, shown only when [MemberRole] is
/// Temporary Guest.
class ExpiryDateRow extends StatelessWidget {
  const ExpiryDateRow({
    super.key,
    required this.expiresAt,
    required this.onPick,
  });

  final DateTime? expiresAt;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      title: const Text('Expires'),
      trailing: Text(
        expiresAt == null ? 'Select date' : formatDate(expiresAt!),
      ),
      onTap: onPick,
    );
  }
}
