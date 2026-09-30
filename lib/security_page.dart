import 'package:flutter/material.dart';
import 'security_service.dart';
import 'util.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});
  @override State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final security = TasklySecurityService.instance;
  bool lockEnabled = false;
  bool biometricEnabled = true;
  bool hasPin = false;
  bool biometricAvailable = false;
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final values = await Future.wait([security.isLockEnabled(), security.isBiometricEnabled(), security.hasPin(), security.canUseBiometrics()]);
    if (!mounted) return;
    setState(() { lockEnabled = values[0] as bool; biometricEnabled = values[1] as bool; hasPin = values[2] as bool; biometricAvailable = values[3] as bool; loading = false; });
  }

  Future<void> _toggleLock(bool value) async {
    if (value) {
      if (!hasPin) {
        final ok = await _setPin();
        if (!ok) return;
      }
      await security.setLockEnabled(true);
    } else {
      final ok = await _confirmUnlockAction();
      if (!ok) return;
      await security.setLockEnabled(false);
    }
    if (mounted) setState(() => lockEnabled = value);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value && !biometricAvailable) {
      _snack(tr('No biometric authentication is available on this device.'));
      return;
    }
    if (value && !await _confirmUnlockAction()) return;
    await security.setBiometricEnabled(value);
    if (mounted) setState(() => biometricEnabled = value);
  }

  Future<bool> _setPin() async {
    final controller = TextEditingController();
    final confirm = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('Create App PIN')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('Use 4 to 8 digits. This PIN is stored securely on the device.')),
          const SizedBox(height: 14),
          TextField(controller: controller, keyboardType: TextInputType.number, obscureText: true, maxLength: 8, decoration: InputDecoration(labelText: tr('PIN'), prefixIcon: const Icon(Icons.pin_rounded))),
          TextField(controller: confirm, keyboardType: TextInputType.number, obscureText: true, maxLength: 8, decoration: InputDecoration(labelText: tr('Confirm PIN'), prefixIcon: const Icon(Icons.verified_user_rounded))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Cancel'))),
          FilledButton(onPressed: () async { if (controller.text != confirm.text || !RegExp(r'^\d{4,8}$').hasMatch(controller.text)) return; await security.setPin(controller.text); if (context.mounted) Navigator.pop(context, true); }, child: Text(tr('Save PIN'))),
        ],
      ),
    );
    if (result == true && mounted) { setState(() => hasPin = true); _snack(tr('App PIN created securely.')); return true; }
    return false;
  }

  Future<void> _changePin() async {
    if (!await _confirmUnlockAction()) return;
    await _setPin();
  }

  Future<bool> _confirmUnlockAction() async {
    if (biometricEnabled && biometricAvailable && await security.authenticateBiometric()) return true;
    if (!hasPin) return false;
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('Verify App PIN')),
        content: TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number, obscureText: true, maxLength: 8, decoration: InputDecoration(labelText: tr('PIN'))),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Cancel'))), FilledButton(onPressed: () async { final ok = await security.verifyPin(controller.text); if (context.mounted) Navigator.pop(context, ok); }, child: Text(tr('Verify')))],
      ),
    );
    return result == true;
  }

  void _snack(String message) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text(tr('Security'), style: const TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 32), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: dark
                  ? const [Color(0xFF1E2B52), Color(0xFF28203C)]
                  : const [Color(0xFFEAF1FF), Color(0xFFF5EEFF)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: CustomColors.primary.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_rounded, color: CustomColors.primary, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Private workspace'),
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('Protect Taskly with device authentication and encrypted local data.'),
                      style: TextStyle(
                        color: dark ? Colors.white70 : CustomColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SecurityCard(icon: Icons.lock_rounded, title: tr('App Lock'), subtitle: lockEnabled ? tr('Taskly locks when you leave the app.') : tr('Require authentication before opening Taskly.'), trailing: Switch.adaptive(value: lockEnabled, onChanged: _toggleLock)),
        _SecurityCard(icon: Icons.fingerprint_rounded, title: tr('Biometric Unlock'), subtitle: biometricAvailable ? tr('Use fingerprint, face unlock, or another enrolled biometric.') : tr('Biometric authentication is not available.'), trailing: Switch.adaptive(value: biometricEnabled && biometricAvailable, onChanged: biometricAvailable ? _toggleBiometric : null)),
        _SecurityCard(icon: Icons.pin_rounded, title: tr('App PIN'), subtitle: hasPin ? tr('A secure fallback PIN is configured.') : tr('Set a 4–8 digit fallback PIN.'), onTap: _changePin, trailing: const Icon(Icons.chevron_right_rounded)),
        _SecurityCard(icon: Icons.enhanced_encryption_rounded, title: tr('Local Encryption'), subtitle: tr('Tasks and notes are encrypted before being stored locally.'), trailing: const Icon(Icons.verified_rounded, color: Colors.green)),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: CustomColors.primary.withOpacity(.07), borderRadius: BorderRadius.circular(18)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline_rounded, color: CustomColors.primary), const SizedBox(width: 12), Expanded(child: Text(tr('Encryption keys are kept in Android secure storage. Existing Taskly data is migrated to encrypted storage the next time the workspace is saved.'), style: const TextStyle(fontSize: 12, height: 1.45)))])),
      ]),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.icon, required this.title, required this.subtitle, this.trailing, this.onTap});
  final IconData icon; final String title; final String subtitle; final Widget? trailing; final VoidCallback? onTap;
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: CustomColors.divider.withOpacity(.8))), child: ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4), leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: CustomColors.primary.withOpacity(.1), shape: BoxShape.circle), child: Icon(icon, color: CustomColors.primary)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: CustomColors.muted)), trailing: trailing));
}
