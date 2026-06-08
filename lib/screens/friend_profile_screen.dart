import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
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
  List<Challenge> _filteredHistory = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'newest';
  String _filterStatus = 'all';

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
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Challenge> filtered = _history.where((c) {
      final matchesSearch = c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesStatus = _filterStatus == 'all' || c.status == _filterStatus;
      
      return matchesSearch && matchesStatus;
    }).toList();

    if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'oldest') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortBy == 'status') {
      filtered.sort((a, b) => a.status.compareTo(b.status));
    }

    setState(() {
      _filteredHistory = filtered;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: AppTheme.black,
            expandedHeight: 280,
            pinned: true,
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
            _buildChallengesTab(),
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

  Widget _buildChallengesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2));
    }

    return Column(
      children: [
        if (_history.isNotEmpty) _buildFilterBar(),
        Expanded(
          child: _filteredHistory.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.padding),
                  itemCount: _filteredHistory.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ChallengeCard(challenge: _filteredHistory[index], showParticipant: false),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppTheme.padding, 12, AppTheme.padding, 0),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
            style: const TextStyle(color: AppTheme.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search challenges...',
              hintStyle: const TextStyle(color: AppTheme.zinc600),
              prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppTheme.zinc600),
              filled: true,
              fillColor: AppTheme.zinc950,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.zinc900),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.zinc900),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Review', 'submitted'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'approved'),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: AppTheme.zinc800),
                const SizedBox(width: 16),
                _buildSortDropdown(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() => _filterStatus = status);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white : AppTheme.zinc950,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.white : AppTheme.zinc900),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.black : AppTheme.zinc500,
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _sortBy,
        dropdownColor: AppTheme.zinc950,
        icon: const Icon(LucideIcons.arrowUpDown, size: 14, color: AppTheme.zinc500),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.zinc500),
        items: const [
          DropdownMenuItem(value: 'newest', child: Text('Newest')),
          DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
          DropdownMenuItem(value: 'status', child: Text('Status')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _sortBy = value);
            _applyFilters();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.history, size: 48, color: AppTheme.zinc800),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No shared history yet.' : 'No matches found.',
            style: const TextStyle(color: AppTheme.zinc600),
          ),
        ],
      ),
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
