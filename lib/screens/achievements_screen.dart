import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/achievement.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';

/// Screen to display user achievements and badges
class AchievementsScreen extends StatelessWidget {
  final bool showAppBar;

  const AchievementsScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('🏆 Achievements'),
            )
          : null,
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Achievement>('achievements').listenable(),
        builder: (context, Box<Achievement> box, _) {
          final achievements = box.values.toList();

          if (achievements.isEmpty) {
            // Initialize achievements if empty
            _initializeAchievements(box);
            return const LoadingWidget(message: 'Loading achievements...');
          }

          final unlocked =
              achievements.where((a) => a.isUnlocked).take(3).toList();
          final locked =
              achievements.where((a) => !a.isUnlocked).take(3).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats card
                Card(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          '${unlocked.length}',
                          'Unlocked',
                          AppTheme.success,
                        ),
                        _buildStatItem(
                          context,
                          '${locked.length}',
                          'In Progress',
                          AppTheme.accent,
                        ),
                        _buildStatItem(
                          context,
                          '${(unlocked.length / achievements.length * 100).toInt()}%',
                          'Complete',
                          AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Unlocked achievements
                if (unlocked.isNotEmpty) ...[
                  Text(
                    '✨ Unlocked (${unlocked.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...unlocked.map((achievement) => _buildAchievementCard(
                        context,
                        achievement,
                        isUnlocked: true,
                      )),
                  const SizedBox(height: 24),
                ],

                // Locked achievements
                if (locked.isNotEmpty) ...[
                  Text(
                    '🔒 In Progress (${locked.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...locked.map((achievement) => _buildAchievementCard(
                        context,
                        achievement,
                        isUnlocked: false,
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement,
      {required bool isUnlocked}) {
    return Card(
      elevation: isUnlocked ? 2 : 0,
      color: isUnlocked
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon/Badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked
                      ? AppTheme.accent
                      : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  isUnlocked ? achievement.icon : '🔒',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress bar (for locked achievements)
                  if (!isUnlocked) ...[
                    LinearProgressIndicator(
                      value: achievement.progressPercentage / 100,
                      backgroundColor: AppTheme.divider,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${achievement.currentProgress}/${achievement.requiredCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  // Unlocked date
                  if (isUnlocked && achievement.unlockedAt != null) ...[
                    Text(
                      'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.success,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  void _initializeAchievements(Box<Achievement> box) {
    final achievements = AchievementDefinitions.getAll();
    for (var achievement in achievements) {
      box.put(achievement.achievementId, achievement);
    }
  }
}
