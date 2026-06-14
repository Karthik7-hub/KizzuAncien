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
import '../widgets/unified_search_field.dart';
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
  late ScrollController _scrollController;
  List<Challenge> _history = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'newest';
  ChallengeCategory _selectedCategory = ChallengeCategory.all;
  final TextEditingController _searchController = TextEditingController();

  String _relationshipStatus = 'NOT_FRIENDS';
  String? _requestId;
  int _relationshipPoints = 0;
  int _friendRelationshipPoints = 0;
  int _friendTotalPoints = 0;
  bool _isActionLoading = false;

  User? _profileUser;
  int _sharedStreak = 0;
  int _sharedLongestStreak = 0;

  final ValueNotifier<double> _titleOpacity = ValueNotifier<double>(0.0);

  double _getTitleOpacity() {
    if (!_scrollController.hasClients) return 0.0;
    final double expandedHeight = _relationshipStatus == 'FRIENDS' ? 450 : 220;
    final double collapsedHeight = 56.0 + MediaQuery.paddingOf(context).top;
    final double scrollOffset = _scrollController.offset;
    final double threshold = expandedHeight - collapsedHeight;
    if (scrollOffset >= threshold) {
      return 1.0;
    } else if (scrollOffset <= threshold - 50) {
      return 0.0;
    } else {
      return (scrollOffset - (threshold - 50)) / 50.0;
    }
  }

  void _updateTitleOpacity() {
    final opacity = _getTitleOpacity();
    if (_titleOpacity.value != opacity) {
      _titleOpacity.value = opacity;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_updateTitleOpacity);

    // Initialize immediately using local provider data to prevent brief flickering
    final friendProvider = context.read<FriendProvider>();
    final isFriend = friendProvider.friends.any((f) => f.id == widget.friend.id);
    final isPendingSent = friendProvider.outgoingRequests.any((r) => r['user'].id == widget.friend.id);
    final isPendingReceived = friendProvider.incomingRequests.any((r) => r['user'].id == widget.friend.id);

    if (isFriend) {
      _relationshipStatus = 'FRIENDS';
    } else if (isPendingSent) {
      _relationshipStatus = 'PENDING_SENT';
      _requestId = friendProvider.getRequestId(widget.friend.id);
    } else if (isPendingReceived) {
      _relationshipStatus = 'PENDING_RECEIVED';
      _requestId = friendProvider.getRequestId(widget.friend.id);
    } else {
      _relationshipStatus = 'NOT_FRIENDS';
    }

    _loadData();
  }

  Future<void> _loadData() async {
    final friendProvider = context.read<FriendProvider>();
    final challengeProvider = context.read<ChallengeProvider>();

    final profileData = await friendProvider.fetchUserProfile(widget.friend.id);
    final challenges = await challengeProvider.fetchSharedChallenges(widget.friend.id);

    if (mounted) {
      setState(() {
        _relationshipStatus = profileData['relationshipStatus'] ?? 'NOT_FRIENDS';
        _requestId = profileData['requestId'];
        _relationshipPoints = profileData['relationshipPoints'] ?? 0;
        _friendRelationshipPoints = profileData['friendRelationshipPoints'] ?? 0;
        _friendTotalPoints = profileData['friendTotalPoints'] ?? 0;
        _sharedStreak = profileData['sharedStreak'] ?? 0;
        _sharedLongestStreak = profileData['sharedLongestStreak'] ?? 0;
        if (profileData['user'] != null) {
          _profileUser = User.fromJson(profileData['user']);
        }
        _history = challenges;
        _isLoading = false;
      });
      _updateTitleOpacity();
    }
  }



  Future<void> _handleFriendAction() async {
    final friendProvider = context.read<FriendProvider>();
    setState(() => _isActionLoading = true);

    bool success = false;
    if (_relationshipStatus == 'NOT_FRIENDS') {
      success = await friendProvider.sendFriendRequest(widget.friend.id);
      if (success && mounted) {
        setState(() {
          _relationshipStatus = 'PENDING_SENT';
        });
        await _loadData();
      }
    } else if (_relationshipStatus == 'PENDING_SENT' && _requestId != null) {
      success = await friendProvider.cancelRequest(_requestId!);
      if (success && mounted) {
        setState(() {
          _relationshipStatus = 'NOT_FRIENDS';
          _requestId = null;
        });
      }
    } else if (_relationshipStatus == 'PENDING_RECEIVED' && _requestId != null) {
      success = await friendProvider.respondToRequest(_requestId!, 'accepted');
      if (success && mounted) {
        setState(() {
          _relationshipStatus = 'FRIENDS';
        });
      }
    }

    if (mounted) {
      setState(() => _isActionLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateTitleOpacity);
    _titleOpacity.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final friendProvider = context.watch<FriendProvider>();
    final challengeProvider = context.watch<ChallengeProvider>();

    // Keep _history in sync with any updates from challengeProvider.challenges
    for (int i = 0; i < _history.length; i++) {
      final updatedIdx = challengeProvider.challenges.indexWhere((c) => c.id == _history[i].id);
      if (updatedIdx != -1) {
        _history[i] = challengeProvider.challenges[updatedIdx];
      }
    }
    
    final currentFriend = friendProvider.friends.firstWhere(
      (f) => f.id == widget.friend.id,
      orElse: () => widget.friend,
    );

    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        backgroundColor: Theme.of(context).cardTheme.color,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              expandedHeight: _relationshipStatus == 'FRIENDS' ? 450 : 220,
              pinned: true,
              centerTitle: true,
              title: ValueListenableBuilder<double>(
                valueListenable: _titleOpacity,
                builder: (context, opacity, child) {
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 100),
                    opacity: opacity,
                    child: Text(
                      currentFriend.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ) ?? TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                },
              ),
              leading: IconButton(
                icon: Icon(LucideIcons.chevronLeft, color: primaryColor),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.only(top: 70),
                  child: Column(
                    children: [
                      AvatarWidget(user: currentFriend, size: 70, showBorder: true),
                      const SizedBox(height: 8),
                      Text(currentFriend.name, style: textTheme.displayMedium),
                      Text('@${currentFriend.username}', style: textTheme.bodyMedium),
                      if (_relationshipStatus == 'FRIENDS') ...[
                        const SizedBox(height: 16),
                        _buildProfileStatsCard(currentFriend, _sharedStreak, _sharedLongestStreak),
                      ],
                      if (currentFriend.lastChallengeCompletedAt != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Last completed ${timeago.format(currentFriend.lastChallengeCompletedAt!)}',
                          style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.labelSmall?.color, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: primaryColor,
                  labelColor: primaryColor,
                  unselectedLabelColor: Theme.of(context).textTheme.labelSmall?.color,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                  tabs: const [
                    Tab(text: 'CHALLENGES'),
                    Tab(text: 'ACTIONS'),
                  ],
                ),
                Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              KeepAliveWrapper(child: _buildChallengesTab(user, currentFriend)),
              KeepAliveWrapper(child: _buildActionsTab()),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildChallengesTab(User? user, User currentFriend) {
    final primaryColor = Theme.of(context).primaryColor;
    debugPrint("DEBUG: FriendProfileScreen _history length: ${_history.length}");
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2));
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.history, size: 48, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.zinc900 : AppTheme.zinc200),
            const SizedBox(height: 16),
            Text('No shared history yet.', style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 13)),
          ],
        ),
      );
    }

    List<Challenge> filtered = _history.where((c) {
      if (_selectedCategory == ChallengeCategory.received && c.recipient.id != user?.id) return false;
      if (_selectedCategory == ChallengeCategory.sent && c.creator.id != user?.id) return false;

      final query = _searchQuery.toLowerCase();
      return c.title.toLowerCase().contains(query) ||
          (c.description?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'oldest') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortBy == 'updated') {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } else if (_sortBy == 'alphabetical') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }

    final pendingReview = filtered
        .where((c) => c.creator.id == user?.id && c.status == 'submitted')
        .toList();

    final awaitingReview = filtered
        .where((c) => c.recipient.id == user?.id && c.status == 'submitted')
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

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _ToolbarHeaderDelegate(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: _buildToolbar(),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppTheme.padding, 0, AppTheme.padding, 80),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (pendingReview.isNotEmpty) ...[
                _buildSectionSubHeader('PENDING REVIEW', color: primaryColor),
                const SizedBox(height: 16),
                ...pendingReview.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ChallengeCard(challenge: c),
                )),
                const SizedBox(height: 32),
              ],

              if (awaitingReview.isNotEmpty) ...[
                _buildSectionSubHeader('AWAITING REVIEW', color: Colors.blueAccent),
                const SizedBox(height: 16),
                ...awaitingReview.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ChallengeCard(challenge: c),
                )),
                const SizedBox(height: 32),
              ],

              if (myActive.isNotEmpty) ...[
                _buildSectionSubHeader('MY ACTIVE'),
                const SizedBox(height: 16),
                ...myActive.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ChallengeCard(challenge: c),
                )),
                const SizedBox(height: 32),
              ],

              if (othersActive.isNotEmpty) ...[
                _buildSectionSubHeader('OTHERS ACTIVE'),
                const SizedBox(height: 16),
                ...othersActive.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ChallengeCard(challenge: c),
                )),
                const SizedBox(height: 32),
              ],

              if (completed.isNotEmpty) ...[
                _buildSectionSubHeader('COMPLETED'),
                const SizedBox(height: 16),
                ...completed.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ChallengeCard(challenge: c),
                )),
              ],

              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      'No challenges matching "$_searchQuery"',
                      style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 13),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: UnifiedSearchField(
            controller: _searchController,
            hintText: 'Search history...',
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(width: 12),
        ChallengeFilterDropdown(
          selectedCategory: _selectedCategory,
          onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: Icon(
            LucideIcons.listFilter,
            size: 20,
            color: isDark ? AppTheme.zinc600 : AppTheme.zinc500,
          ),
          color: isDark ? AppTheme.zinc950 : AppTheme.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
          ),
          onSelected: (value) => setState(() => _sortBy = value),
          itemBuilder: (context) => [
            _buildSortItem('newest', 'Newest First'),
            _buildSortItem('oldest', 'Oldest First'),
            _buildSortItem('updated', 'Recently Updated'),
            _buildSortItem('alphabetical', 'Alphabetical'),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? (isDark ? AppTheme.white : AppTheme.zinc950)
              : (isDark ? AppTheme.zinc500 : AppTheme.zinc600),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSectionSubHeader(String title, {Color? color}) {
    final activeColor = color ?? Theme.of(context).textTheme.labelSmall?.color ?? AppTheme.zinc700;
    return Row(
      children: [
        Container(width: 2, height: 10, decoration: BoxDecoration(color: activeColor)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: activeColor, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildActionsTab() {
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.padding * 1.5),
      child: Column(
        children: [
          if (_relationshipStatus == 'FRIENDS') ...[
            _buildActionCard(
              'Challenge',
              'Send a new challenge to your friend.',
              LucideIcons.plus,
              primaryColor,
              bgColor,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateChallengeScreen(recipient: widget.friend))),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              'Truth',
              'Spend 50 points to ask a question.',
              LucideIcons.helpCircle,
              isDark ? AppTheme.zinc900 : AppTheme.zinc100,
              primaryColor,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => TruthDareScreen(
                recipient: widget.friend.copyWith(relationshipPoints: _relationshipPoints)
              ))),
              borderColor: isDark ? AppTheme.zinc800 : AppTheme.zinc200,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              'Dare',
              'Spend 100 points to assign a task.',
              LucideIcons.zap,
              isDark ? AppTheme.zinc900 : AppTheme.zinc100,
              primaryColor,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => TruthDareScreen(
                recipient: widget.friend.copyWith(relationshipPoints: _relationshipPoints)
              ))),
              borderColor: isDark ? AppTheme.zinc800 : AppTheme.zinc200,
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
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String text = 'Add Friend';
    IconData icon = LucideIcons.userPlus;
    Color bg = primaryColor;
    Color fg = bgColor;

    if (_relationshipStatus == 'PENDING_SENT') {
      text = 'Request Sent';
      icon = LucideIcons.clock;
      bg = isDark ? AppTheme.zinc900 : AppTheme.zinc100;
      fg = primaryColor;
    } else if (_relationshipStatus == 'PENDING_RECEIVED') {
      text = 'Accept Request';
      icon = LucideIcons.check;
      bg = primaryColor;
      fg = bgColor;
    } else if (_relationshipStatus == 'FRIENDS') {
      text = 'Friends';
      icon = LucideIcons.users;
      bg = isDark ? AppTheme.zinc900 : AppTheme.zinc100;
      fg = primaryColor;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomButton(
        text: text,
        isLoading: _isActionLoading,
        onPressed: _relationshipStatus == 'FRIENDS' ? null : _handleFriendAction,
        backgroundColor: bg,
        textColor: fg,
        icon: Icon(icon, size: 20, color: fg),
      ),
    );
  }

  Widget _buildProfileStatsCard(User friend, int sharedStreak, int sharedLongestStreak) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F12) : AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1D1D22) : AppTheme.zinc200, width: 1.2),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatDetailItem('$sharedStreak', 'Current Streak', LucideIcons.flame, const Color(0xFFFF9500)),
              _buildStatDivider(),
              _buildStatDetailItem('$sharedLongestStreak', 'Shared Record', LucideIcons.flame, const Color(0xFFFF5B00)),
              _buildStatDivider(),
              _buildStatDetailItem('${_profileUser?.longestStreak ?? friend.longestStreak}', 'Lifetime Record', LucideIcons.flame, const Color(0xFFFF3B30)),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Divider(color: isDark ? const Color(0xFF1D1D22) : AppTheme.zinc200, height: 1, thickness: 1),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatDetailItem('$_relationshipPoints', 'My Points', LucideIcons.sparkles, const Color(0xFF34C759)),
              _buildStatDivider(),
              _buildStatDetailItem('$_friendRelationshipPoints', 'Their Points', LucideIcons.award, const Color(0xFF5856D6)),
              _buildStatDivider(),
              _buildStatDetailItem('$_friendTotalPoints', 'Total Points', LucideIcons.trophy, const Color(0xFFAF52DE)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(width: 1, height: 44, color: isDark ? const Color(0xFF1D1D22) : AppTheme.zinc200);
  }

  Widget _buildStatDetailItem(String value, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.1 : 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Theme.of(context).primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.zinc500 : AppTheme.zinc600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor;
  }
}

class _ToolbarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color backgroundColor;

  _ToolbarHeaderDelegate({required this.child, required this.backgroundColor});

  @override
  double get minExtent => 76.0;
  @override
  double get maxExtent => 76.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 76.0,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_ToolbarHeaderDelegate oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor || child != oldDelegate.child;
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
