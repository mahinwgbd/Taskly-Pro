import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

import 'profile.dart';
import 'util.dart';
import 'google_drive_sync.dart';
import 'backup_page.dart';
import 'sync_page.dart';
import 'pro_page.dart';
import 'security_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.profile, required this.onThemeChanged, required this.cloudSync, required this.onSync, required this.onCloudRestore, required this.onBackupRestored});
  final ProfileController profile;
  final ValueChanged<ThemeMode> onThemeChanged;
  final GoogleDriveSyncService cloudSync;
  final Future<void> Function() onSync;
  final Future<void> Function() onCloudRestore;
  final Future<void> Function() onBackupRestored;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => notificationsEnabled = prefs.getBool('notifications_enabled') ?? true);
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => notificationsEnabled = value);
    final granted = await NotificationService.instance.setEnabled(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value && !granted ? tr('Please allow notifications in Android settings.') : value ? tr('Notifications enabled') : tr('Notifications disabled'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.profile,
      builder: (context, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(tr('Settings'), style: TextStyle(fontWeight: FontWeight.w900)),
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _SettingsProfileCard(
              profile: widget.profile,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage(profile: widget.profile))),
            ),
            const SizedBox(height: 22),
            Text(tr('Preferences'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.notifications_active_rounded,
              title: tr('Notifications'),
              subtitle: notificationsEnabled ? tr('Reminders are turned on') : tr('Reminders are turned off'),
              onTap: _openNotifications,
              trailing: Switch.adaptive(value: notificationsEnabled, onChanged: _setNotifications),
            ),
            if (notificationsEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await NotificationService.instance.sendTestNotification();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? tr('Test notification sent') : tr('Notification permission is not available.'))));
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(tr('Send test notification')),
                ),
              ),
            _SettingsTile(
              icon: Icons.palette_rounded,
              title: tr('Appearance'),
              subtitle: _themeLabel(context),
              onTap: _openAppearance,
            ),
            _SettingsTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Taskly Pro',
              subtitle: 'Advanced productivity tools and Pro workspace',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasklyProPage())),
            ),
            _SettingsTile(
              icon: Icons.shield_rounded,
              title: tr('Security'),
              subtitle: tr('App Lock, biometrics, PIN and encryption'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecurityPage())),
            ),
            _SettingsTile(
              icon: Icons.backup_rounded,
              title: tr('Backup & Restore'),
              subtitle: tr('Export or restore your Taskly workspace'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BackupPage(onRestored: widget.onBackupRestored))),
            ),
            _SettingsTile(
              icon: Icons.info_rounded,
              title: tr('About Taskly'),
              subtitle: tr('Version 2.3.0 • Taskly Pro'),
              onTap: _openAbout,
            ),
            const SizedBox(height: 18),
            Text(tr('Developer'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const _DeveloperCard(),
            const SizedBox(height: 18),
            CloudSyncCard(sync: widget.cloudSync, onSync: widget.onSync, onRestore: widget.onCloudRestore),
            const SizedBox(height: 20),
            _SettingsHint(icon: Icons.auto_awesome_rounded, text: tr('Your workspace is personal. Shape it around the way you work and live.')),
          ],
        ),
      ),
    );
  }

  String _themeLabel(BuildContext context) => switch (Theme.of(context).brightness) {
        Brightness.dark => 'Dark theme is active',
        Brightness.light => 'Light theme is active',
      };

  Future<void> _openNotifications() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Notifications'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(tr('Stay on top of the things that matter.'), style: TextStyle(color: CustomColors.muted)),
          const SizedBox(height: 18),
          _SwitchRow(title: tr('Task reminders'), subtitle: tr('Get a nudge when a task is due.'), value: notificationsEnabled, onChanged: _setNotifications),
          _SwitchRow(title: tr('Daily focus check-in'), subtitle: tr('A gentle reminder to review your day.'), value: notificationsEnabled, onChanged: _setNotifications),
        ]),
      ),
    );
  }

  Future<void> _openAppearance() async {
    final current = Theme.of(context).brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AppearanceSheet(current: current, onChanged: (mode) {
        Navigator.pop(context);
        widget.onThemeChanged(mode);
      }),
    );
  }

  Future<void> _openAbout() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [CustomColors.primary, Color(0xFF8CB9FF)]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.check_rounded, color: Colors.white, size: 28)),
          const SizedBox(width: 12),
          const Text('Taskly', style: TextStyle(fontWeight: FontWeight.w900)),
        ]),
        content: Text(tr('A calm little workspace for tasks, notes, projects, and everyday progress.\n\nVersion 2.3.0\nTaskly Pro — security, automation, and deeper productivity for your everyday workflow.'), style: TextStyle(height: 1.5, color: CustomColors.muted)),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr('Done')))],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.profile});
  final ProfileController profile;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController profession;
  late final TextEditingController company;
  late final TextEditingController designation;
  late final TextEditingController department;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController location;
  late final TextEditingController bio;
  late final TextEditingController facebook;
  late final TextEditingController instagram;
  late final TextEditingController linkedin;
  late final TextEditingController github;
  late final TextEditingController website;
  String gender = '';
  String bloodGroup = '';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    name = TextEditingController(text: p.name);
    profession = TextEditingController(text: p.profession);
    company = TextEditingController(text: p.company);
    designation = TextEditingController(text: p.designation);
    department = TextEditingController(text: p.department);
    phone = TextEditingController(text: p.phone);
    email = TextEditingController(text: p.email);
    location = TextEditingController(text: p.location);
    bio = TextEditingController(text: p.bio);
    facebook = TextEditingController(text: p.facebook);
    instagram = TextEditingController(text: p.instagram);
    linkedin = TextEditingController(text: p.linkedin);
    github = TextEditingController(text: p.github);
    website = TextEditingController(text: p.website);
    gender = p.gender;
    bloodGroup = p.bloodGroup;
  }

  @override
  void dispose() {
    for (final controller in [name, profession, company, designation, department, phone, email, location, bio, facebook, instagram, linkedin, github, website]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return AnimatedBuilder(
      animation: p,
      builder: (context, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(tr('My Profile'), style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(onPressed: saving ? null : _save, tooltip: tr('Save'), icon: Icon(Icons.check_rounded)),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
            children: [
              _ProfileHero(profile: p, onChangePhoto: saving ? null : _changePhoto),
              const SizedBox(height: 28),
              _SectionLabel(icon: Icons.person_outline_rounded, title: tr('Personal information'), subtitle: tr('The basics people use to know you.')),
              const SizedBox(height: 12),
              _Field(controller: name, label: tr('Full name'), icon: Icons.person_rounded, requiredField: true, capitalization: TextCapitalization.words),
              _Field(controller: profession, label: tr('Profession'), icon: Icons.badge_rounded, hint: tr('e.g. Software Engineer')),
              _DropdownField(label: tr('Gender'), icon: Icons.wc_rounded, value: gender, items: ['Male', 'Female', 'Other', 'Prefer not to say'], onChanged: (v) => setState(() => gender = v ?? '')),
              _DropdownField(label: tr('Blood group'), icon: Icons.bloodtype_rounded, value: bloodGroup, items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], onChanged: (v) => setState(() => bloodGroup = v ?? '')),
              _Field(controller: location, label: tr('Address'), icon: Icons.location_on_rounded, hint: tr('City / Country')),
              _Field(controller: bio, label: tr('About me'), icon: Icons.notes_rounded, hint: tr('A short line about yourself'), maxLines: 3),
              const SizedBox(height: 14),
              _SectionLabel(icon: Icons.work_outline_rounded, title: tr('Professional'), subtitle: tr('Make your work or study identity visible.')),
              const SizedBox(height: 12),
              _Field(controller: company, label: tr('Company / Institution'), icon: Icons.business_rounded, hint: tr('Where you work or study')),
              _Field(controller: designation, label: tr('Designation'), icon: Icons.workspace_premium_rounded, hint: tr('e.g. Senior Engineer')),
              _Field(controller: department, label: tr('Department'), icon: Icons.account_tree_rounded, hint: tr('Optional')),
              const SizedBox(height: 14),
              _SectionLabel(icon: Icons.contact_phone_rounded, title: tr('Contact'), subtitle: tr('Keep your important contact details together.')),
              const SizedBox(height: 12),
              _Field(controller: phone, label: tr('Phone'), icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
              _Field(controller: email, label: tr('Mail'), icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _SectionLabel(icon: Icons.link_rounded, title: tr('Social & web'), subtitle: tr('Add the places where people can find you.')),
              const SizedBox(height: 12),
              _Field(controller: facebook, label: tr('Facebook'), icon: Icons.facebook_rounded, hint: tr('Profile link or username')),
              _Field(controller: instagram, label: tr('Instagram'), icon: Icons.camera_alt_rounded, hint: tr('Profile link or username')),
              _Field(controller: linkedin, label: tr('LinkedIn'), icon: Icons.work_rounded, hint: tr('Profile link or username')),
              _Field(controller: github, label: tr('GitHub'), icon: Icons.code_rounded, hint: tr('Profile link or username')),
              _Field(controller: website, label: tr('Personal website'), icon: Icons.language_rounded, hint: 'https://...'),
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
                  label: Text(saving ? tr('Saving profile...') : tr('Save profile'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(backgroundColor: CustomColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: saving ? null : _reset, icon: Icon(Icons.restart_alt_rounded), label: Text(tr('Reset profile'), style: TextStyle(fontWeight: FontWeight.w700)), style: OutlinedButton.styleFrom(foregroundColor: CustomColors.TrashRed, minimumSize: Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)))),
              const SizedBox(height: 16),
              _InfoCard(icon: Icons.cloud_done_outlined, title: tr('Private & synced by your choice'), subtitle: tr('Your profile stays local unless you connect Google Drive backup in Settings.')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    await widget.profile.saveDetails(
      name: name.text,
      profession: profession.text,
      gender: gender,
      bloodGroup: bloodGroup,
      company: company.text,
      designation: designation.text,
      department: department.text,
      phone: phone.text,
      email: email.text,
      location: location.text,
      bio: bio.text,
      facebook: facebook.text,
      instagram: instagram.text,
      linkedin: linkedin.text,
      github: github.text,
      website: website.text,
    );
    if (mounted) {
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Profile saved successfully.'))));
    }
  }

  Future<void> _changePhoto() async {
    setState(() => saving = true);
    final changed = await widget.profile.pickAndSavePhoto();
    if (mounted) {
      setState(() => saving = false);
      if (changed) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Profile photo updated.'))));
    }
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Reset profile?')),
        content: Text(tr('Your personal, professional, contact, and social details will be cleared and the default Taskly profile will be restored.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('Reset'))),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.profile.resetProfile();
    _syncControllers();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Default profile restored.'))));
  }

  void _syncControllers() {
    final p = widget.profile;
    name.text = p.name;
    profession.text = p.profession;
    company.text = p.company;
    designation.text = p.designation;
    department.text = p.department;
    phone.text = p.phone;
    email.text = p.email;
    location.text = p.location;
    bio.text = p.bio;
    facebook.text = p.facebook;
    instagram.text = p.instagram;
    linkedin.text = p.linkedin;
    github.text = p.github;
    website.text = p.website;
    setState(() {
      gender = p.gender;
      bloodGroup = p.bloodGroup;
    });
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.onChangePhoto});
  final ProfileController profile;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    Widget info(IconData icon, String text) => Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [Icon(icon, size: 13, color: Colors.white70), const SizedBox(width: 6), Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)))]));
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [CustomColors.primary, Color(0xFF8CB9FF)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x335B7CFA), blurRadius: 25, offset: Offset(0, 12))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: ProfileAvatar(profile: profile, radius: 43),
          ),
          Positioned(right: -2, bottom: -2, child: Material(color: CustomColors.accent, shape: const CircleBorder(), child: InkWell(onTap: onChangePhoto, customBorder: const CircleBorder(), child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white))))),
        ]),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('YOUR PROFILE'), style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
          const SizedBox(height: 5),
          Text(profile.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
          if (profile.profession.isNotEmpty) info(Icons.work_outline_rounded, profile.profession),
          if (profile.designation.isNotEmpty) info(Icons.badge_outlined, profile.designation),
          if (profile.company.isNotEmpty) info(Icons.business_outlined, profile.company),
          if (profile.bloodGroup.isNotEmpty) info(Icons.bloodtype_outlined, '${tr('Blood group')}: ${profile.bloodGroup}'),
          if (profile.phone.isNotEmpty) info(Icons.phone_outlined, profile.phone),
          if (profile.email.isNotEmpty) info(Icons.email_outlined, profile.email),
          if (profile.location.isNotEmpty) info(Icons.location_on_outlined, profile.location),
        ])),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 38, height: 38, decoration: BoxDecoration(color: CustomColors.primary.withOpacity(.10), shape: BoxShape.circle), child: Icon(icon, color: CustomColors.primary, size: 19)),
    const SizedBox(width: 11),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 10.5, color: CustomColors.muted))])),
  ]);
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, required this.icon, this.hint, this.requiredField = false, this.maxLines = 1, this.keyboardType, this.capitalization = TextCapitalization.none});
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool requiredField;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    validator: requiredField ? (value) => (value == null || value.trim().isEmpty) ? tr('Please enter your name') : null : null,
    decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon)),
  ));
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.label, required this.icon, required this.value, required this.items, required this.onChanged});
  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(
    value: value.isEmpty ? null : value,
    items: [DropdownMenuItem<String>(value: '', child: Text(tr('Not set'))), ...items.map((item) => DropdownMenuItem(value: item, child: Text(tr(item))))],
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  ));
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 14, offset: Offset(0, 5))]),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: CustomColors.primary.withOpacity(.14), width: 3)), child: const CircleAvatar(backgroundImage: AssetImage('assets/profile/mahin_profile.jpg'))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('Meet the developer'), style: TextStyle(fontSize: 11, color: CustomColors.primary, fontWeight: FontWeight.w900, letterSpacing: .5)),
        SizedBox(height: 4),
        Text('Mahin Mahbub Ullah', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        SizedBox(height: 3),
        Text(tr('IT Enthusiasts'), style: TextStyle(fontSize: 11, color: CustomColors.muted, fontWeight: FontWeight.w700)),
        SizedBox(height: 7),
        Row(children: [Icon(Icons.email_outlined, size: 14, color: CustomColors.primary), SizedBox(width: 5), Expanded(child: Text('mahinwgbd@gmail.com', style: TextStyle(fontSize: 10.5, color: CustomColors.muted))) ]),
        SizedBox(height: 4),
        Row(children: [Icon(Icons.location_on_outlined, size: 14, color: CustomColors.primary), SizedBox(width: 5), Expanded(child: Text('Bashundhara R/A', style: TextStyle(fontSize: 10.5, color: CustomColors.muted))) ]),
      ])),
    ]),
  );
}

class _SettingsProfileCard extends StatelessWidget {
  const _SettingsProfileCard({required this.profile, required this.onTap});
  final ProfileController profile;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final subtitle = [profile.profession, profile.company].where((e) => e.isNotEmpty).join(' • ');
    return Material(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
      ProfileAvatar(profile: profile, radius: 30),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('Profile'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(profile.name, style: const TextStyle(fontSize: 13, color: CustomColors.muted)),
        const SizedBox(height: 4),
        Text(subtitle.isEmpty ? tr('Add your personal & work details') : subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: CustomColors.primary, fontWeight: FontWeight.w800)),
      ])),
      const Icon(Icons.chevron_right_rounded, color: CustomColors.muted),
    ]))));
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.trailing});
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap; final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: CustomColors.divider.withOpacity(.85), width: 1), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 5))]), child: ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3), leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: CustomColors.primary.withOpacity(.10), shape: BoxShape.circle), child: Icon(icon, color: CustomColors.primary, size: 21)), title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: CustomColors.muted)), trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: CustomColors.muted)));
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.subtitle, required this.value, required this.onChanged});
  final String title; final String subtitle; final bool value; final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: CustomColors.muted)), trailing: Switch.adaptive(value: value, onChanged: onChanged));
}

class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet({required this.current, required this.onChanged});
  final ThemeMode current; final ValueChanged<ThemeMode> onChanged;
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(22, 6, 22, 32), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('Appearance'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), SizedBox(height: 6), Text(tr('Choose how Taskly should look.'), style: TextStyle(color: CustomColors.muted)), SizedBox(height: 18), _ModeTile(icon: Icons.light_mode_rounded, title: tr('Light'), subtitle: tr('Clean and bright'), selected: current == ThemeMode.light, onTap: () => onChanged(ThemeMode.light)), _ModeTile(icon: Icons.dark_mode_rounded, title: tr('Dark'), subtitle: tr('Easy on the eyes at night'), selected: current == ThemeMode.dark, onTap: () => onChanged(ThemeMode.dark)), _ModeTile(icon: Icons.phone_android_rounded, title: tr('System'), subtitle: tr('Follow your device'), selected: current == ThemeMode.system, onTap: () => onChanged(ThemeMode.system))]));
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.icon, required this.title, required this.subtitle, required this.selected, required this.onTap});
  final IconData icon; final String title; final String subtitle; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: selected ? CustomColors.primary.withOpacity(.08) : Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? CustomColors.primary : Colors.transparent)), child: ListTile(onTap: onTap, leading: Icon(icon, color: selected ? CustomColors.primary : CustomColors.muted), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: CustomColors.muted)), trailing: selected ? const Icon(Icons.check_circle_rounded, color: CustomColors.primary) : const Icon(Icons.radio_button_unchecked_rounded, color: CustomColors.muted)));
}

class _SettingsHint extends StatelessWidget {
  const _SettingsHint({required this.icon, required this.text});
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0x145B7CFA), Color(0x10A97CFF)]), borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(icon, color: CustomColors.primary), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w700)))]));
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title; final String subtitle;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: CustomColors.primary.withOpacity(.08), borderRadius: BorderRadius.circular(18)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: CustomColors.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 11, height: 1.4, color: CustomColors.muted))]))]));
}
