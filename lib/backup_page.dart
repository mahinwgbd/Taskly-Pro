import 'package:flutter/material.dart';

import 'backup_service.dart';
import 'util.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key, required this.onRestored});
  final Future<void> Function() onRestored;

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final service = TasklyBackupService();
  bool exporting = false;
  bool importing = false;

  Future<void> _export() async {
    setState(() => exporting = true);
    try {
      final path = await service.exportBackup();
      if (!mounted) return;
      if (path == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('Backup exported successfully.')}\n$path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('Could not export the backup.')} $e')));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('Restore backup?')),
        content: Text(tr('Restoring replaces your current tasks, notes, profile and selected settings with the backup data. This cannot be undone.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('Restore'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => importing = true);
    try {
      final result = await service.importBackup();
      if (!mounted || result == null) return;
      await widget.onRestored();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('Backup restored successfully.')} ${localizeNumber(result.taskCount)} ${tr('tasks')}, ${localizeNumber(result.noteCount)} ${tr('notes')}.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('Could not restore the backup.')} $e')));
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr('Backup & Restore'), style: const TextStyle(fontWeight: FontWeight.w900))),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [CustomColors.primary.withOpacity(.16), CustomColors.purple.withOpacity(.10)]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.cloud_download_rounded, size: 38, color: CustomColors.primary),
            const SizedBox(height: 14),
            Text(tr('Keep your workspace safe'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(tr('Create a portable Taskly backup or restore one later on this device.'), style: TextStyle(color: CustomColors.muted, height: 1.45)),
          ]),
        ),
        const SizedBox(height: 18),
        _BackupTile(icon: Icons.upload_file_rounded, title: tr('Export backup'), subtitle: tr('Save tasks, notes, profile, settings and profile photo as a JSON backup.'), busy: exporting, onTap: exporting || importing ? null : _export),
        _BackupTile(icon: Icons.restore_rounded, title: tr('Restore backup'), subtitle: tr('Replace the current workspace with a previously exported Taskly backup.'), busy: importing, onTap: exporting || importing ? null : _import),
        const SizedBox(height: 14),
        Text(tr('Tip: keep a backup before changing phones or clearing app data.'), style: TextStyle(color: CustomColors.muted, fontSize: 12, height: 1.4)),
      ],
    ),
  );
}

class _BackupTile extends StatelessWidget {
  const _BackupTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.busy = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: CustomColors.primary.withOpacity(.10), borderRadius: BorderRadius.circular(15)), child: busy ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, color: CustomColors.primary)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: TextStyle(color: CustomColors.muted, height: 1.35))),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}
