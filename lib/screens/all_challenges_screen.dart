import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/challenge_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/challenge_card.dart';
import '../widgets/challenge_filter_dropdown.dart';
import '../models/challenge.dart';

import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';

import '../widgets/unified_search_field.dart';

class AllChallengesScreen extends StatefulWidget {
  const AllChallengesScreen({super.key});

  @override
  State<AllChallengesScreen> createState() => _AllChallengesScreenState();
}

class _AllChallengesScreenState extends State<AllChallengesScreen> with AutomaticKeepAliveClientMixin {
  ChallengeCategory _selectedCategory = ChallengeCategory.all;
  String _searchQuery = '';
  String _sortBy = 'newest';
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final challengeProvider = context.read<ChallengeProvider>();
      if (challengeProvider.challenges.isEmpty) {
        challengeProvider.fetchChallenges();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final challengeProvider = context.watch<ChallengeProvider>();
    final user = context.watch<AuthProvider>().user;

    if (user == null) return const SizedBox.shrink();

    List<Challenge> filtered = challengeProvider.challenges.where((c) {
      if (_selectedCategory == ChallengeCategory.received && c.recipient.id != user.id) return false;
      if (_selectedCategory == ChallengeCategory.sent && c.creator.id != user.id) return false;
      
      final query = _searchQuery.toLowerCase();
      return c.title.toLowerCase().contains(query) || (c.description?.toLowerCase().contains(query) ?? false);
    }).toList();

    // Sorting
    if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'oldest') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortBy == 'updated') {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } else if (_sortBy == 'alphabetical') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppHeader(
        title: 'Challenges',
        centerTitle: false,
        actions: [
          ChallengeFilterDropdown(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: UnifiedSearchField(
                    controller: _searchController,
                    hintText: 'Search challenges...',
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                _buildSortMenu(),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => challengeProvider.fetchChallenges(),
              color: Theme.of(context).primaryColor,
              backgroundColor: Theme.of(context).cardTheme.color,
              child: filtered.isEmpty && !challengeProvider.isLoading
                  ? const EmptyState(
                      icon: LucideIcons.layoutList,
                      title: 'No challenges found',
                      isScrollable: true,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ChallengeCard(challenge: filtered[index]),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<String>(
      icon: Icon(LucideIcons.listFilter, size: 20, color: isDark ? AppTheme.zinc600 : AppTheme.zinc500),
      color: isDark ? AppTheme.zinc950 : AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
      ),
      onSelected: (value) => setState(() => _sortBy = value),
      itemBuilder: (context) => [
        _buildSortItem(context, 'newest', 'Newest First'),
        _buildSortItem(context, 'oldest', 'Oldest First'),
        _buildSortItem(context, 'updated', 'Recently Updated'),
        _buildSortItem(context, 'alphabetical', 'Alphabetical'),
      ],
    );
  }

  PopupMenuItem<String> _buildSortItem(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? (isDark ? AppTheme.white : AppTheme.zinc950) : (isDark ? AppTheme.zinc500 : AppTheme.zinc600),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
