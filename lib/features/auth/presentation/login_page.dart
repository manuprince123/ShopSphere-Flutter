import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final password = TextEditingController();
  bool visible = false;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final busy = auth.status == AuthStatus.submitting;
    return Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: Form(key: formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 70, height: 70, alignment: Alignment.center,
            decoration: BoxDecoration(color: AppTheme.jade, borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 34)),
          const SizedBox(height: 34),
          Text('Good things await.', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text('Sign in to explore your next favourite find.'),
          const SizedBox(height: 34),
          TextFormField(controller: username, textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
            validator: (value) => (value?.trim().length ?? 0) < 3 ? 'Enter at least 3 characters' : null),
          const SizedBox(height: 16),
          TextFormField(controller: password, obscureText: !visible,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(tooltip: visible ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => visible = !visible),
                icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined))),
            validator: (value) => (value?.length ?? 0) < 6 ? 'Enter at least 6 characters' : null,
            onFieldSubmitted: (_) => submit()),
          if (auth.message != null) ...[
            const SizedBox(height: 16),
            Text(auth.message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: busy ? null : submit,
            child: busy ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in')),
          const SizedBox(height: 20),
          const Text('Demo access  ·  emilys / emilyspass', textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64716D))),
        ]))),
    ))));
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    await context.read<AuthController>().signIn(username.text, password.text);
  }
}
