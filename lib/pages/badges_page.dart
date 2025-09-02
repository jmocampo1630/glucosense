import 'package:flutter/material.dart';
import 'package:glucolook/models/badge.model.dart' as BadgeModel;
import 'package:glucolook/services/badge.service.dart';
import 'package:glucolook/widgets/badge_widgets.dart';

class BadgesPage extends StatefulWidget {
  final String patientId;

  const BadgesPage({
    super.key,
    required this.patientId,
  });

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> with TickerProviderStateMixin {
  final BadgeService _badgeService = BadgeService();
  List<BadgeModel.Badge> _badges = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  late TabController _tabController;

  final List<String> _filterOptions = [
    'all',
    'unlocked',
    'locked',
  ];

  final List<String> _rarityOptions = [
    'all',
    'common',
    'rare',
    'epic',
    'legendary',
  ];

  final List<String> _categoryOptions = [
    'all',
    'milestone',
    'streak',
    'health',
    'feature',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final badges = await _badgeService.getBadges(widget.patientId);

      setState(() {
        _badges = badges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading badges: $e')),
        );
      }
    }
  }

  List<BadgeModel.Badge> get _filteredBadges {
    List<BadgeModel.Badge> filtered = _badges;

    switch (_selectedFilter) {
      case 'unlocked':
        filtered = filtered.where((b) => b.isUnlocked).toList();
        break;
      case 'locked':
        filtered = filtered.where((b) => !b.isUnlocked).toList();
        break;
    }

    return filtered;
  }

  List<BadgeModel.Badge> _getBadgesByCategory(String category) {
    List<BadgeModel.Badge> filtered = _filteredBadges;

    if (category != 'all') {
      filtered = filtered.where((b) => b.category == category).toList();
    }

    return filtered;
  }

  List<BadgeModel.Badge> _getBadgesByRarity(String rarity) {
    List<BadgeModel.Badge> filtered = _filteredBadges;

    if (rarity != 'all') {
      filtered = filtered.where((b) => b.rarity == rarity).toList();
    }

    return filtered;
  }

  int get _unlockedCount {
    return _badges.where((b) => b.isUnlocked).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badge Collection'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Badges'),
            Tab(text: 'By Category'),
            Tab(text: 'By Rarity'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildFilterBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllBadgesList(),
                      _buildCategoryView(),
                      _buildRarityView(),
                    ],
                  ),
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
            Icons.military_tech,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Badge Collection',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_unlockedCount / ${_badges.length} Badges Earned',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _badges.isEmpty ? 0 : _unlockedCount / _badges.length,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = filter == _selectedFilter;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
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

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'unlocked':
        return 'Earned';
      case 'locked':
        return 'Locked';
      default:
        return filter;
    }
  }

  Widget _buildAllBadgesList() {
    final badges = _filteredBadges;

    if (badges.isEmpty) {
      return const Center(
        child: Text('No badges found for this filter.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return BadgeCard(
          badge: badge,
          onTap: () {
            if (badge.isUnlocked) {
              BadgeUnlockedDialog.show(context, badge);
            }
          },
        );
      },
    );
  }

  Widget _buildCategoryView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categoryOptions.length,
      itemBuilder: (context, index) {
        final category = _categoryOptions[index];
        final categoryBadges = _getBadgesByCategory(category);

        if (category == 'all' || categoryBadges.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _getCategoryLabel(category),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: categoryBadges.length,
              itemBuilder: (context, badgeIndex) {
                final badge = categoryBadges[badgeIndex];
                return GestureDetector(
                  onTap: () {
                    if (badge.isUnlocked) {
                      BadgeUnlockedDialog.show(context, badge);
                    }
                  },
                  child: Column(
                    children: [
                      BadgeWidget(
                        badge: badge,
                        size: 60,
                        showDetails: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        badge.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildRarityView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rarityOptions.length,
      itemBuilder: (context, index) {
        final rarity = _rarityOptions[index];
        final rarityBadges = _getBadgesByRarity(rarity);

        if (rarity == 'all' || rarityBadges.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getRarityColor(rarity),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getRarityLabel(rarity),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getRarityColor(rarity),
                        ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: rarityBadges.length,
              itemBuilder: (context, badgeIndex) {
                final badge = rarityBadges[badgeIndex];
                return GestureDetector(
                  onTap: () {
                    if (badge.isUnlocked) {
                      BadgeUnlockedDialog.show(context, badge);
                    }
                  },
                  child: Column(
                    children: [
                      BadgeWidget(
                        badge: badge,
                        size: 60,
                        showDetails: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        badge.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'milestone':
        return 'Milestone Badges 🎯';
      case 'streak':
        return 'Streak Badges ⚡';
      case 'health':
        return 'Health Badges 💚';
      case 'feature':
        return 'Feature Badges 🌟';
      default:
        return category;
    }
  }

  String _getRarityLabel(String rarity) {
    switch (rarity) {
      case 'common':
        return 'Common Badges';
      case 'rare':
        return 'Rare Badges';
      case 'epic':
        return 'Epic Badges';
      case 'legendary':
        return 'Legendary Badges';
      default:
        return rarity;
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return const Color(0xFF9E9E9E);
      case 'rare':
        return const Color(0xFF2196F3);
      case 'epic':
        return const Color(0xFF9C27B0);
      case 'legendary':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
