import 'package:flutter/material.dart';
import 'package:glucolook/models/achievement.model.dart';

class AchievementUnlockedDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockedDialog({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(int.parse(achievement.getCategoryColor().substring(1),
                          radix: 16) +
                      0xFF000000)
                  .withOpacity(0.1),
              Color(int.parse(achievement.getCategoryColor().substring(1),
                          radix: 16) +
                      0xFF000000)
                  .withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti or celebration icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(int.parse(
                        achievement.getCategoryColor().substring(1),
                        radix: 16) +
                    0xFF000000),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Color(int.parse(
                                achievement.getCategoryColor().substring(1),
                                radix: 16) +
                            0xFF000000)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  achievement.getCategoryIcon(),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Achievement unlocked text
            Text(
              'Achievement Unlocked!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Color(int.parse(
                            achievement.getCategoryColor().substring(1),
                            radix: 16) +
                        0xFF000000),
                  ),
            ),
            const SizedBox(height: 16),
            // Achievement name
            Text(
              achievement.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Achievement description
            Text(
              achievement.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(int.parse(
                          achievement.getCategoryColor().substring(1),
                          radix: 16) +
                      0xFF000000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementUnlockedDialog(achievement: achievement),
    );
  }
}

class AchievementNotificationWidget extends StatefulWidget {
  final List<Achievement> newAchievements;
  final VoidCallback onDismiss;

  const AchievementNotificationWidget({
    super.key,
    required this.newAchievements,
    required this.onDismiss,
  });

  @override
  State<AchievementNotificationWidget> createState() =>
      _AchievementNotificationWidgetState();
}

class _AchievementNotificationWidgetState
    extends State<AchievementNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.newAchievements.isEmpty) {
      return const SizedBox.shrink();
    }

    final achievement = widget.newAchievements.first;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: Color(int.parse(
                          achievement.getCategoryColor().substring(1),
                          radix: 16) +
                      0xFF000000),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                              achievement.getCategoryColor().substring(1),
                              radix: 16) +
                          0xFF000000),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        achievement.getCategoryIcon(),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievement Unlocked!',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Color(int.parse(
                                            achievement
                                                .getCategoryColor()
                                                .substring(1),
                                            radix: 16) +
                                        0xFF000000),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          achievement.name,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (widget.newAchievements.length > 1)
                          Text(
                            '+${widget.newAchievements.length - 1} more',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
