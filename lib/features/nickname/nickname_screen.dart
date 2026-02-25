import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/player_provider.dart';
import '../../routing/app_router.dart';

/// Screen to set or edit the local player's nickname and avatar colour.
class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});

  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  final _controller = TextEditingController();
  int _selectedAvatar = 0;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing nickname if available.
    final existing = ref.read(localPlayerProvider);
    if (existing != null) {
      _controller.text = existing.nickname;
      _selectedAvatar = existing.avatarIndex;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    await ref
        .read(localPlayerProvider.notifier)
        .setProfile(nickname: name, avatarIndex: _selectedAvatar);

    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Avatar preview
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.playerColors[_selectedAvatar],
                  child: Text(
                    _controller.text.isEmpty
                        ? '?'
                        : _controller.text[0].toUpperCase(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                ),
              ).animate().scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 32),
              // Nickname field
              TextField(
                controller: _controller,
                maxLength: 12,
                textCapitalization: TextCapitalization.words,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(
                  hintText: 'Enter nickname',
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),
              // Avatar colour picker
              Text(
                'Pick your colour',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(8, (i) {
                  final isSelected = i == _selectedAvatar;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 48 : 36,
                      height: isSelected ? 48 : 36,
                      decoration: BoxDecoration(
                        color: AppColors.playerColors[i],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.playerColors[i].withAlpha(
                                    150,
                                  ),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(flex: 2),
              // Save button
              ElevatedButton(
                onPressed: _controller.text.trim().isEmpty ? null : _save,
                child: const Text("Let's Go!"),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
