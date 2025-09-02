import 'package:flutter/material.dart';
import 'package:glucolook/models/badge.model.dart' as BadgeModel;

class BadgeWidget extends StatelessWidget {
  final BadgeModel.Badge badge;
  final double size;
  final bool showDetails;

  const BadgeWidget({
    super.key,
    required this.badge,
    this.size = 80,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: badge.isUnlocked ? badge.backgroundColor : Colors.grey[300],
        border: Border.all(
          color: badge.isUnlocked ? badge.borderColor : Colors.grey[400]!,
          width: 3,
        ),
        boxShadow: badge.isUnlocked
            ? [
                BoxShadow(
                  color: badge.getRarityColor().withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge Icon/Emoji
          Text(
            badge.isUnlocked ? badge.iconPath : '🔒',
            style: TextStyle(
              fontSize: size * 0.4,
            ),
          ),
          if (showDetails && size > 60) ...[
            const SizedBox(height: 4),
            Text(
              badge.getRarityLabel(),
              style: TextStyle(
                fontSize: size * 0.1,
                fontWeight: FontWeight.bold,
                color: badge.isUnlocked ? badge.getRarityColor() : Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BadgeCard extends StatelessWidget {
  final BadgeModel.Badge badge;
  final VoidCallback? onTap;

  const BadgeCard({
    super.key,
    required this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: badge.isUnlocked ? 4 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Badge Widget
              BadgeWidget(
                badge: badge,
                size: 60,
                showDetails: true,
              ),
              const SizedBox(width: 16),
              // Badge Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            badge.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: badge.isUnlocked
                                      ? null
                                      : Colors.grey[600],
                                ),
                          ),
                        ),
                        // Rarity indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badge.getRarityColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: badge.getRarityColor(),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            badge.getRarityLabel(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badge.getRarityColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: badge.isUnlocked
                                ? Colors.grey[700]
                                : Colors.grey[500],
                          ),
                    ),
                    const SizedBox(height: 8),
                    // Unlocked date or locked status
                    if (badge.isUnlocked && badge.unlockedAt != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Unlocked: ${_formatDate(badge.unlockedAt!)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Not unlocked yet',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[400],
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class BadgeUnlockedDialog extends StatefulWidget {
  final BadgeModel.Badge badge;

  const BadgeUnlockedDialog({
    super.key,
    required this.badge,
  });

  @override
  State<BadgeUnlockedDialog> createState() => _BadgeUnlockedDialogState();
}

class _BadgeUnlockedDialogState extends State<BadgeUnlockedDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animations
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _rotationController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_scaleController, _fadeController, _rotationController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Dialog(
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
                    widget.badge.backgroundColor.withOpacity(0.1),
                    widget.badge.backgroundColor.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge earned animation with scale and rotation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: RotationTransition(
                      turns: _rotationAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.badge.backgroundColor,
                          border: Border.all(
                            color: widget.badge.borderColor,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.badge
                                  .getRarityColor()
                                  .withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.badge.iconPath,
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Badge unlocked text
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Badge Earned!',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: widget.badge.getRarityColor(),
                              ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rarity indicator
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.badge.getRarityColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.badge.getRarityColor(),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '${widget.badge.getRarityLabel()} Badge',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.badge.getRarityColor(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Badge name
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      widget.badge.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Badge description
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      widget.badge.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Close button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.badge.getRarityColor(),
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void show(BuildContext context, BadgeModel.Badge badge) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BadgeUnlockedDialog(badge: badge),
    );
  }
}

// Standalone function to show badge unlock dialog
void showBadgeUnlockedDialog(BuildContext context, BadgeModel.Badge badge) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => BadgeUnlockedDialog(badge: badge),
  );
}

class BadgeNotificationWidget extends StatefulWidget {
  final BadgeModel.Badge badge;
  final VoidCallback onDismiss;

  const BadgeNotificationWidget({
    super.key,
    required this.badge,
    required this.onDismiss,
  });

  @override
  State<BadgeNotificationWidget> createState() =>
      _BadgeNotificationWidgetState();
}

class _BadgeNotificationWidgetState extends State<BadgeNotificationWidget>
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
                  color: widget.badge.getRarityColor(),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  BadgeWidget(
                    badge: widget.badge,
                    size: 50,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Badge Earned!',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: widget.badge.getRarityColor(),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          widget.badge.name,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          '${widget.badge.getRarityLabel()} Badge',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: widget.badge.getRarityColor(),
                                    fontWeight: FontWeight.w500,
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
