import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/models/player.dart';
import '../../state/providers.dart';
import '../home/home_shell.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  void _enterArena(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (_) => false,
    );
  }

  void _demoProviderSignIn(
      BuildContext context, WidgetRef ref, AuthProvider provider) {
    final label = provider == AuthProvider.google ? 'Google' : 'Apple';
    ref
        .read(authProvider.notifier)
        .signInDemoProvider(provider, name: '$label Player');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$label sign-in connects with Firebase at launch — using a demo '
            'account for now.'),
      ),
    );
    _enterArena(context);
  }

  Future<void> _emailSignIn(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _EmailSheet(),
    );
    if (result == null || !context.mounted) return;
    ref
        .read(authProvider.notifier)
        .signInEmail(name: result.$1, email: result.$2);
    _enterArena(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandMark(size: 118)),
                  const SizedBox(height: 22),
                  Text(
                    'Anthropic Arena',
                    textAlign: TextAlign.center,
                    style: textTheme.displaySmall
                        ?.copyWith(color: AppColors.cream),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LEARN · PLAY · COMPETE',
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.gold,
                      letterSpacing: 3.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    onPressed: () =>
                        _demoProviderSignIn(context, ref, AuthProvider.google),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.ink,
                    ),
                    onPressed: () =>
                        _demoProviderSignIn(context, ref, AuthProvider.apple),
                    icon: const Icon(Icons.apple_rounded, size: 24),
                    label: const Text('Continue with Apple'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cream,
                      side: const BorderSide(
                          color: AppColors.strokeDark, width: 1.4),
                    ),
                    onPressed: () => _emailSignIn(context, ref),
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text('Continue with Email'),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).signInGuest();
                      _enterArena(context);
                    },
                    child: const Text('Play as guest'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your progress is saved on this device. Sign in when the '
                    'global arena goes live to compete worldwide.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall
                        ?.copyWith(color: const Color(0xFF77808F)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailSheet extends StatefulWidget {
  const _EmailSheet();

  @override
  State<_EmailSheet> createState() => _EmailSheetState();
}

class _EmailSheetState extends State<_EmailSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Join the arena',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Display name'),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context)
                      .pop((_name.text.trim(), _email.text.trim()));
                }
              },
              child: const Text('Start learning'),
            ),
          ],
        ),
      ),
    );
  }
}
