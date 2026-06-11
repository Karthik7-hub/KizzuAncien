import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/challenge_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/challenge_card.dart';
import '../widgets/challenge_filter_dropdown.dart';
import '../models/challenge.dart';

class AllChallengesScreen extends StatefulWidget {
  const AllChallengesScreen({super.key});

  @override
  State<AllChallengesScreen> createState() => _AllChallengesScreenState();
}

class _AllChallengesScreenState extends State<AllChallengesScreen> {
  ChallengeCategory _selectedCategory = ChallengeCategory.all;
  String _searchQuery = '';
  String _sortBy = 'newest';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().fetchChallenges();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: AppTheme.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                    letterSpacing: -1,
                  ),
                ),
                Row(
                  children: [
                    ChallengeFilterDropdown(
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                    ),
                    const SizedBox(width: 8),
                    _buildSortMenu(),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: AppTheme.white),
              decoration: InputDecoration(
                hintText: 'Search history...',
                hintStyle: const TextStyle(color: AppTheme.zinc600),
                prefixIcon: const Icon(LucideIcons.search, color: AppTheme.zinc500, size: 20),
                filled: true,
                fillColor: AppTheme.zinc900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'ALL CHALLENGES',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500, letterSpacing: 1.5),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => challengeProvider.fetchChallenges(),
              color: AppTheme.white,
              backgroundColor: AppTheme.zinc900,
              child: filtered.isEmpty && !challengeProvider.isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.layoutList, size: 48, color: AppTheme.zinc800),
          SizedBox(height: 16),
          Text('No challenges found', style: TextStyle(color: AppTheme.zinc600)),
        ],
      ),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.listFilter, size: 20, color: AppTheme.zinc600),
      color: AppTheme.zinc950,
      onSelected: (value) => setState(() => _sortBy = value),
      itemBuilder: (context) => [
        _buildSortItem('newest', 'Newest First'),
        _buildSortItem('oldest', 'Oldest First'),
        _buildSortItem('updated', 'Recently Updated'),
        _buildSortItem('alphabetical', 'Alphabetical'),
      ],
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label) {
    final isSelected = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.white : AppTheme.zinc500,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
