import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/custom_button.dart';
import '../widgets/challenge_card.dart';
import 'create_challenge_screen.dart';
import 'truth_dare_screen.dart';

class FriendProfileScreen extends StatefulWidget {
  final User friend;
  const FriendProfileScreen({super.key, required this.friend});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Challenge> _history = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'newest'; // newest, oldest, updated, alphabetical
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final challenges = await context.read<ChallengeProvider>().fetchSharedChallenges(widget.friend.id);
    if (mounted) {
      setState(() {
        _history = challenges;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: AppTheme.black,
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  AvatarWidget(user: widget.friend, size: 80, showBorder: true),
                  const SizedBox(height: 16),
                  Text(widget.friend.name, style: textTheme.displayMedium),
                  Text('@${widget.friend.username}', style: textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniStat('${widget.friend.streak}', 'STREAK', LucideIcons.flame, AppTheme.accent),
                      const SizedBox(width: 24),
                      _buildMiniStat('${widget.friend.points}', 'POINTS', LucideIcons.award, Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.white,
                labelColor: AppTheme.white,
                unselectedLabelColor: AppTheme.zinc600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                tabs: const [
                  Tab(text: 'CHALLENGES'),
                  Tab(text: 'ACTIONS'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildChallengesTab(user),
            _buildActionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.white)),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.zinc600, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChallengesTab(User? user) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2));
    }

    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.history, size: 48, color: AppTheme.zinc900),
            SizedBox(height: 16),
            Text('No shared history yet.', style: TextStyle(color: AppTheme.zinc700, fontSize: 13)),
          ],
        ),
      );
    }

    // 1. Filter
    List<Challenge> filtered = _history.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.title.toLowerCase().contains(query) ||
          (c.description?.toLowerCase().contains(query) ?? false);
    }).toList();

    // 2. Sort
    if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'oldest') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortBy == 'updated') {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } else if (_sortBy == 'alphabetical') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }

    // 3. Group
    final pendingReview = filtered
        .where((c) => c.creator.id == user?.id && c.status == 'submitted')
        .toList();

    final myActive = filtered
        .where((c) => c.recipient.id == user?.id && c.status == 'pending')
        .toList();

    final othersActive = filtered
        .where((c) => c.creator.id == user?.id && c.status == 'pending')
        .toList();

    final completed = filtered
        .where((c) => c.status == 'approved' || c.status == 'rejected')
        .toList();

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppTheme.white,
      backgroundColor: AppTheme.zinc950,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.padding),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(),
            const SizedBox(height: 32),

            if (pendingReview.isNotEmpty) ...[
              _buildSectionSubHeader('PENDING REVIEW', color: AppTheme.white),
              const SizedBox(height: 16),
              ...pendingReview.map((c) => _buildChallengeItem(c)),
              const SizedBox(height: 32),
            ],

            if (myActive.isNotEmpty) ...[
              _buildSectionSubHeader('MY ACTIVE'),
              const SizedBox(height: 16),
              ...myActive.map((c) => _buildChallengeItem(c)),
              const SizedBox(height: 32),
            ],

            if (othersActive.isNotEmpty) ...[
              _buildSectionSubHeader('OTHERS ACTIVE'),
              const SizedBox(height: 16),
              ...othersActive.map((c) => _buildChallengeItem(c)),
              const SizedBox(height: 32),
            ],

            if (completed.isNotEmpty) ...[
              _buildSectionSubHeader('COMPLETED'),
              const SizedBox(height: 16),
              ...completed.map((c) => _buildChallengeItem(c)),
            ],

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: Text(
                    'No challenges matching "$_searchQuery"',
                    style: const TextStyle(color: AppTheme.zinc700, fontSize: 13),
                  ),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: AppTheme.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search history...',
                  hintStyle: const TextStyle(color: AppTheme.zinc700),
                  prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppTheme.zinc700),
                  filled: true,
                  fillColor: AppTheme.zinc950,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.zinc900),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.listFilter, size: 20, color: AppTheme.zinc600),
              color: AppTheme.zinc950,
              onSelected: (value) => setState(() => _sortBy = value),
              itemBuilder: (context) => [
                _buildSortItem('newest', 'Newest First'),
                _buildSortItem('oldest', 'Oldest First'),
                _buildSortItem('updated', 'Recently Updated'),
                _buildSortItem('alphabetical', 'Alphabetical'),
              ],
            ),
          ],
        ),
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

  Widget _buildSectionSubHeader(String title, {Color color = AppTheme.zinc700}) {
    return Row(
      children: [
        Container(width: 2, height: 10, decoration: BoxDecoration(color: color)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildChallengeItem(Challenge challenge) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ChallengeCard(challenge: challenge),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.padding * 1.5),
      child: Column(
        children: [
          CustomButton(
            text: 'Send New Challenge',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateChallengeScreen(recipient: widget.friend))),
            backgroundColor: AppTheme.white,
            textColor: AppTheme.black,
            icon: const Icon(LucideIcons.plus, size: 20),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Send Truth or Dare',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TruthDareScreen(recipient: widget.friend))),
            backgroundColor: AppTheme.zinc900,
            textColor: AppTheme.white,
            borderColor: AppTheme.zinc800,
            icon: const Icon(LucideIcons.zap, size: 20),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.black,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
