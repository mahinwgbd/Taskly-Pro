import 'package:flutter/material.dart';

import 'google_auth_config.dart';
import 'google_drive_sync.dart';
import 'util.dart';

class CloudSyncCard extends StatelessWidget {
  const CloudSyncCard({super.key, required this.sync, required this.onSync, required this.onRestore});
  final GoogleDriveSyncService sync;
  final Future<void> Function() onSync;
  final Future<void> Function() onRestore;

  Future<void> _openSetup(BuildContext context) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Google OAuth Setup'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(tr('Paste the Web application OAuth client ID from Google Cloud Console. This is not a password. Android also needs an OAuth client matching Taskly’s package name and SHA-1.'), style: const TextStyle(color: CustomColors.muted, fontSize: 11.5, height: 1.4)),
          const SizedBox(height: 14),
          TextField(controller: controller, decoration: InputDecoration(labelText: tr('Web Client ID'), hintText: '1234567890-xxxxx.apps.googleusercontent.com')),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
            final value = controller.text.trim();
            if (!isValidGoogleWebClientId(value)) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(tr('Enter a valid Web Client ID ending in .apps.googleusercontent.com'))));
              return;
            }
            final saved = await sync.saveServerClientId(value);
            if (!saved) return;
            if (sheetContext.mounted) Navigator.pop(sheetContext);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Google Client ID saved. Restart Taskly, then connect Google Drive.'))));
          }, child: Text(tr('Save & Restart Taskly')))),
        ]),
      ),
    );
    controller.dispose();
  }

  Future<void> _restore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('Restore from Google Drive?')),
        content: Text(tr('Taskly will create a local safety snapshot first, then replace the current workspace with the cloud backup. This will not delete your Google Drive backup.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('Restore'))),
        ],
      ),
    );
    if (confirmed != true || sync.isBusy) return;
    await onRestore();
    if (!context.mounted) return;
    final message = sync.errorMessage == null ? tr('Cloud backup restored successfully.') : sync.errorMessage!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: sync,
        builder: (context, _) {
          final user = sync.user;
          final dark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF151925) : null,
              gradient: dark ? null : LinearGradient(
                colors: user == null ? [const Color(0xFFF4F7FF), const Color(0xFFEAF0FF)] : [const Color(0xFFEAF9F1), const Color(0xFFDDF4E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: user == null ? CustomColors.primary.withOpacity(.10) : CustomColors.green.withOpacity(.18)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Icon(user == null ? Icons.cloud_off_rounded : Icons.cloud_done_rounded, color: user == null ? CustomColors.primary : CustomColors.green)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('Google Drive Backup'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(user == null ? tr('Manual cloud backup. Nothing is uploaded until you tap Backup Now.') : '${tr('Connected as')} ${user.email}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: CustomColors.muted)),
                ])),
              ]),
              const SizedBox(height: 14),
              if (sync.errorMessage != null) ...[
                Text(sync.errorMessage!, style: const TextStyle(fontSize: 10.5, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
              ],
              if (user == null) ...[
                Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: sync.isBusy ? null : () => _openSetup(context), icon: const Icon(Icons.key_rounded, size: 16), label: Text(tr('Google OAuth Setup')))),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: sync.isBusy ? null : () async { final ok = await sync.signIn(); if (ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Google Drive connected.')))); }, icon: sync.isBusy ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.login_rounded), label: Text(sync.isBusy ? tr('Connecting...') : tr('Connect Google Drive')))),
              ] else ...[
                Row(children: [
                  Expanded(child: FilledButton.icon(onPressed: sync.isBusy ? null : onSync, icon: const Icon(Icons.cloud_upload_rounded, size: 18), label: Text(sync.isBusy ? tr('Backing up...') : tr('Backup Now')))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(onPressed: sync.isBusy ? null : () => _restore(context), icon: const Icon(Icons.cloud_download_rounded, size: 18), label: Text(tr('Restore')))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text(tr('Manual mode: your data is uploaded only when you choose Backup Now.'), style: const TextStyle(fontSize: 9.5, color: CustomColors.muted, height: 1.35))),
                  IconButton(tooltip: tr('Disconnect'), onPressed: sync.isBusy ? null : () => sync.signOut(), icon: const Icon(Icons.logout_rounded)),
                ]),
              ],
            ]),
          );
        },
      );
}
