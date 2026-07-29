import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../state/providers.dart';

/// The provider sign-in buttons — Google, Apple, email and optionally guest.
///
/// Shared by the full-screen [LoginScreen] and the Certifications tab's
/// sign-in gate. The gate embeds these **in place** so a locked tab can sign
/// someone in without a route push: `authProvider` flips, the tab rebuilds and
/// the catalogue appears. Callers that need to move somewhere afterwards
/// (the login screen entering the arena) pass [onSignedIn]; callers that just
/// watch the provider can leave it null.
class SignInOptions extends ConsumerStatefulWidget {
  const SignInOptions({
    super.key,
    this.onSignedIn,
    this.showGuest = true,
  });

  /// Fired once a sign-in succeeds. Null = nothing to do beyond the rebuild.
  final VoidCallback? onSignedIn;

  /// Whether to offer "Play as guest". Hidden where a guest session is already
  /// running (the Certifications gate) — signing in as a guest again is a no-op
  /// and would leave the tab still locked.
  final bool showGuest;

  @override
  ConsumerState<SignInOptions> createState() => _SignInOptionsState();
}

class _SignInOptionsState extends ConsumerState<SignInOptions> {
  bool _busy = false;

  /// Runs a sign-in action; on success notifies [SignInOptions.onSignedIn],
  /// on failure surfaces the returned message.
  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      widget.onSignedIn?.call();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _emailSignIn() async {
    final result = await showModalBottomSheet<(String, String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _EmailSheet(),
    );
    if (result == null || !mounted) return;
    await _run(() => ref
        .read(authProvider.notifier)
        .signInEmail(name: result.$1, email: result.$2, password: result.$3));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _run(() => ref.read(authProvider.notifier).signInGoogle()),
          icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
          label: const Text('Continue with Google'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.ink,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _busy
              ? null
              : () =>
                  _run(() => ref.read(authProvider.notifier).signInDemoApple()),
          icon: const Icon(Icons.apple_rounded, size: 24),
          label: const Text('Continue with Apple'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.cream,
            side: const BorderSide(color: AppColors.strokeDark, width: 1.4),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _busy ? null : _emailSignIn,
          icon: const Icon(Icons.mail_outline_rounded),
          label: const Text('Continue with Email'),
        ),
        if (widget.showGuest) ...[
          const SizedBox(height: 20),
          TextButton(
            onPressed: _busy
                ? null
                : () =>
                    _run(() => ref.read(authProvider.notifier).signInGuest()),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Play as guest'),
          ),
        ] else if (_busy) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ],
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
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
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
            const SizedBox(height: 6),
            Text(
              'New here? This creates your account. Returning? Same form '
              'signs you back in.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'At least 6 characters' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop(
                      (_name.text.trim(), _email.text.trim(), _password.text));
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
