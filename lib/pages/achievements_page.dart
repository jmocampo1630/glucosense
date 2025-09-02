import 'package:flutter/material.dart';
import 'package:glucolook/models/achievement.model.dart';
import 'package:glucolook/models/achievement_stats.model.dart';
import 'package:glucolook/services/achievement.service.dart';

class AchievementsPage extends StatefulWidget {
  final String patientId;

  const AchievementsPage({
    super.key,
    required this.patientId,
  });

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final AchievementService _achievementService = AchievementService();
  List<Achievement> _achievements = [];
  AchievementStats _stats = AchievementStats();
  bool _isLoading = true;
  String _selectedCategory = 'all';

  final List<String> _categories = [
    'all',
    'milestone',
    'streak',
    'health',
    'feature',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final achievements =
          await _achievementService.getAchievements(widget.patientId);
      final stats =
          await _achievementService.getAchievementStats(widget.patientId);

      setState(() {
        _achievements = achievements;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading achievements: $e')),
        );
      }
    }
  }

  List<Achievement> get _filteredAchievements {
    if (_selectedCategory == 'all') {
      return _achievements;
    }
    return _achievements.where((a) => a.category == _selectedCategory).toList();
  }

  int get _unlockedCount {
    return _achievements.where((a) => a.isUnlocked).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildCategoryFilter(),
                Expanded(
                  child: _buildAchievementsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Progress',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_unlockedCount / ${_achievements.length} Achievements Unlocked',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _achievements.isEmpty
                ? 0
                : _unlockedCount / _achievements.length,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(_getCategoryLabel(category)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'all':
        return 'All';
      case 'milestone':
        return 'Milestones';
      case 'streak':
        return 'Streaks';
      case 'health':
        return 'Health';
      case 'feature':
        return 'Features';
      default:
        return category;
    }
  }

  Widget _buildAchievementsList() {
    final filteredAchievements = _filteredAchievements;

    if (filteredAchievements.isEmpty) {
      return const Center(
        child: Text('No achievements found for this category.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredAchievements.length,
      itemBuilder: (context, index) {
        final achievement = filteredAchievements[index];
        return _buildAchievementCard(achievement);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final progress =
        _achievementService.getAchievementProgress(achievement, _stats);
    final currentValue = _stats.getValueByField(achievement.condition.field);
    final targetValue = achievement.condition.value;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Achievement Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? Color(int.parse(
                            achievement.getCategoryColor().substring(1),
                            radix: 16) +
                        0xFF000000)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  achievement.getCategoryIcon(),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Achievement Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              achievement.isUnlocked ? null : Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: achievement.isUnlocked
                              ? Colors.grey[700]
                              : Colors.grey[500],
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  if (!achievement.isUnlocked) ...[
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(int.parse(
                                achievement.getCategoryColor().substring(1),
                                radix: 16) +
                            0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentValue / $targetValue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                  // Unlocked date
                  if (achievement.isUnlocked &&
                      achievement.unlockedAt != null) ...[
                    Text(
                      'Unlocked: ${_formatDate(achievement.unlockedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Status indicator
            if (achievement.isUnlocked)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey[400],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
