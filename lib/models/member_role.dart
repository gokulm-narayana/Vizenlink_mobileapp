/// Shared account-access role for Users & Invites members and invites/
/// create-user drafts. Informational only — there's no sharing/permissions
/// backend to actually enforce these yet (see CLAUDE.md).
enum MemberRole { owner, familyViewer, temporaryGuest }

const memberRoleLabels = {
  MemberRole.owner: 'Owner',
  MemberRole.familyViewer: 'Family Viewer',
  MemberRole.temporaryGuest: 'Temporary Guest',
};

const memberRoleDescriptions = {
  MemberRole.owner:
      'Full camera/site control, sharing, settings, retention, export, '
      'decommission',
  MemberRole.familyViewer:
      'Assigned live view, selected playback, selected alerts, optional '
      'two-way talk',
  MemberRole.temporaryGuest:
      'Time-limited access to selected camera/live view only',
};
