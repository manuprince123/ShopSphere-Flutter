import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => sl<ProfileController>()..load(),
    child: const _ProfileBody(),
  );
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Text(
            'Your profile',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: switch (profile.status) {
            ProfileStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            ProfileStatus.failure => ErrorView(
              message: profile.failure!.message,
              onRetry: profile.load,
            ),
            ProfileStatus.ready => _ProfileDetails(profile: profile),
          },
        ),
      ],
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile});
  final ProfileController profile;

  @override
  Widget build(BuildContext context) {
    final user = profile.user!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: CircleAvatar(
            radius: 46,
            backgroundColor: const Color(0xFFE5EEE7),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: user.image,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const Icon(Icons.person, size: 44),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          user.fullName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          '@${user.email.split('@').first}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.jade),
        ),
        const SizedBox(height: 30),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(user.email),
              ),
              const Divider(height: 1, indent: 58),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Phone'),
                subtitle: Text(user.phone),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.read<AuthController>().signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
