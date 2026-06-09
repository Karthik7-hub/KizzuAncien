import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/user.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/custom_button.dart';
import '../widgets/challenge_card.dart';
import '../widgets/challenge_filter_dropdown.dart';
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
  ChallengeCategory _selectedCategory = ChallengeCategory.all;
  final TextEditingController _searchController = TextEditingController();

  String _relationshipStatus = 'NOT_FRIENDS';
  String? _requestId;
  int _relationshipPoints = 0;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final profileData = await context.read<FriendProvider>().fetchUserProfile(widget.friend.id);
    final challenges = await context.read<ChallengeProvider>().fetchSharedChallenges(widget.friend.id);
    
    if (mounted) {
      setState(() {
        _relationshipStatus = profileData['relationshipStatus'] ?? 'NOT_FRIENDS';
        _requestId = profileData['requestId'];
        _relationshipPoints = profileData['relationshipPoints'] ?? 0;
        _history = challenges;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    final challenges = await context.read<ChallengeProvider>().fetchSharedChallenges(widget.friend.id);
    if (mounted) {
      setState(() {
        _history = challenges;
      });
    }
  }

  Future<void> _handleFriendAction() async {
    final friendProvider = context.read<FriendProvider>();
    setState(() => _isActionLoading = true);

    bool success = false;
    if (_relationshipStatus == 'NOT_FRIENDS') {
      success = await friendProvider.sendFriendRequest(widget.friend.id);
      if (success) {
        _relationshipStatus = 'PENDING_SENT';
        // Reload data to get the requestId
        await _loadData();
      }
    } else if (_relationshipStatus == 'PENDING_SENT' && _requestId != null) {
      success = await friendProvider.cancelRequest(_requestId!);
      if (success) {
        _relationshipStatus = 'NOT_FRIENDS';
        _requestId = null;
      }
    } else if (_relationshipStatus == 'PENDING_RECEIVED' && _requestId != null) {
      success = await friendProvider.respondToRequest(_requestId!, 'accepted');
      if (success) {
        _relationshipStatus = 'FRIENDS';
      }
    }

    if (mounted) {
      setState(() => _isActionLoading = false);
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
    final friendProvider = context.watch<FriendProvider>();
    
    // Use live friend data from provider if available
    final currentFriend = friendProvider.friends.firstWhere(
      (f) => f.id == widget.friend.id,
      orElse: () => widget.friend,
    );

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
                  AvatarWidget(user: currentFriend, size: 80, showBorder: true),
                  const SizedBox(height: 16),
                  Text(currentFriend.name, style: textTheme.displayMedium),
                  Text('@${currentFriend.username}', style: textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniStat('${currentFriend.sharedStreak ?? 0}', 'STREAK', LucideIcons.zap, AppTheme.white),
                      const SizedBox(width: 24),
                      _buildMiniStat('$_relationshipPoints', 'POINTS', LucideIcons.award, AppTheme.white),
                    ],
                  ),
                  if (currentFriend.lastChallengeCompletedAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Last completed ${timeago.format(currentFriend.lastChallengeCompletedAt!)}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.zinc600, fontWeight: FontWeight.bold),
                    ),
                  ],
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
      if (_selectedCategory == ChallengeCategory.received && c.recipient.id != user?.id) return false;
      if (_selectedCategory == ChallengeCategory.sent && c.creator.id != user?.id) return false;

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
            ChallengeFilterDropdown(
              selectedCategory: _selectedCategory,
              onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
            ),
            const SizedBox(width: 8),
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
          if (_relationshipStatus == 'FRIENDS') ...[
            _buildActionCard(
              'Challenge',
              'Send a new challenge to your friend.',
              LucideIcons.plus,
              AppTheme.white,
              AppTheme.black,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateChallengeScreen(recipient: widget.friend))),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              'Truth',
              'Spend 50 points to ask a question.',
              LucideIcons.helpCircle,
              AppTheme.zinc900,
              AppTheme.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => TruthDareScreen(
                recipient: widget.friend.copyWith(relationshipPoints: _relationshipPoints)
              ))),
              borderColor: AppTheme.zinc800,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              'Dare',
              'Spend 100 points to assign a task.',
              LucideIcons.zap,
              AppTheme.zinc900,
              AppTheme.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => TruthDareScreen(
                recipient: widget.friend.copyWith(relationshipPoints: _relationshipPoints)
              ))),
              borderColor: AppTheme.zinc800,
            ),
          ] else
            _buildRelationshipButton(),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String desc, IconData icon, Color bg, Color fg, VoidCallback onTap, {Color? borderColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: fg, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: fg.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: fg.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipButton() {
    String text = 'Add Friend';
    IconData icon = LucideIcons.userPlus;
    Color bg = AppTheme.white;
    Color fg = AppTheme.black;

    if (_relationshipStatus == 'PENDING_SENT') {
      text = 'Request Sent';
      icon = LucideIcons.clock;
      bg = AppTheme.zinc900;
      fg = AppTheme.white;
    } else if (_relationshipStatus == 'PENDING_RECEIVED') {
      text = 'Accept Request';
      icon = LucideIcons.check;
      bg = AppTheme.white;
      fg = AppTheme.black;
    }

    return CustomButton(
      text: text,
      isLoading: _isActionLoading,
      onPressed: _handleFriendAction,
      backgroundColor: bg,
      textColor: fg,
      icon: Icon(icon, size: 20),
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
