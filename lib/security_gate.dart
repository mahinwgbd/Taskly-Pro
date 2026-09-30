import 'package:flutter/material.dart';
import 'security_service.dart';
import 'util.dart';

class SecurityGate extends StatefulWidget {
  const SecurityGate({super.key, required this.child});
  final Widget child;
  @override State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> with WidgetsBindingObserver {
  final security = TasklySecurityService.instance;
  bool locked = false;
  bool loading = true;
  bool authenticating = false;

  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _prepare(); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) _lockIfEnabled(); if (state == AppLifecycleState.resumed) _unlockIfNeeded(); }

  Future<void> _prepare() async { final enabled = await security.isLockEnabled(); if (!mounted) return; setState(() { locked = enabled; loading = false; }); if (enabled) await _unlockIfNeeded(); }
  Future<void> _lockIfEnabled() async { if (await security.isLockEnabled() && mounted) setState(() => locked = true); }
  Future<void> _unlockIfNeeded() async { if (!await security.isLockEnabled() || !mounted || !locked || authenticating) return; await _authenticate(); }

  Future<void> _authenticate() async {
    setState(() => authenticating = true);
    var ok = false;
    if (await security.isBiometricEnabled() && await security.canUseBiometrics()) ok = await security.authenticateBiometric();
    if (!ok && await security.hasPin()) {
      final controller = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(children: [const Icon(Icons.lock_rounded), const SizedBox(width: 10), Text(tr('Taskly Locked'))]),
          content: TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number, obscureText: true, maxLength: 8, decoration: InputDecoration(labelText: tr('App PIN'))),
          actions: [FilledButton(onPressed: () async { final valid = await security.verifyPin(controller.text); if (context.mounted) Navigator.pop(context, valid); }, child: Text(tr('Unlock')))],
        ),
      );
      ok = result == true;
    }
    if (mounted) { setState(() { locked = !ok; authenticating = false; }); if (!ok) _snack(tr('Authentication required to continue.')); }
  }

  void _snack(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Material(child: Center(child: CircularProgressIndicator()));
    }
    if (!locked) return widget.child;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: CustomColors.primary.withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 42,
                  color: CustomColors.primary,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                tr('Taskly is locked'),
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                tr('Unlock to continue to your private workspace.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: CustomColors.muted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: authenticating ? null : _authenticate,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: Text(tr('Unlock Taskly')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
