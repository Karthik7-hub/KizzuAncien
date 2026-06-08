import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/challenge.dart';
import '../models/user.dart';
import '../providers/challenge_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/challenge_card.dart';
import '../widgets/avatar_widget.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  String _searchQuery = '';
  String _sortBy = 'newest';
  String _filterStatus = 'all';
  bool _groupByFriend = false;

  @override
  Widget build(BuildContext context) {
    final challengeProvider = context.watch<ChallengeProvider>();
    final user = context.read<AuthProvider>().user;

    List<Challenge> filtered = challengeProvider.challenges.where((c) {
      final matchesSearch = c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          c.creator.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.recipient.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _filterStatus == 'all' || c.status == _filterStatus;
      
      return matchesSearch && matchesStatus;
    }).toList();

    // Sorting
    if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'oldest') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortBy == 'status') {
      filtered.sort((a, b) => a.status.compareTo(b.status));
    } else if (_sortBy == 'friend') {
      filtered.sort((a, b) {
        final otherA = a.creator.id == user?.id ? a.recipient.name : a.creator.name;
        final otherB = b.creator.id == user?.id ? b.recipient.name : b.creator.name;
        return otherA.compareTo(otherB);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        title: const Text('Challenges', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_groupByFriend ? LucideIcons.list : LucideIcons.users, size: 20),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _groupByFriend = !_groupByFriend);
            },
            tooltip: _groupByFriend ? 'Show List' : 'Group by Friend',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => challengeProvider.fetchChallenges(),
              color: AppTheme.white,
              backgroundColor: AppTheme.zinc900,
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : _groupByFriend 
                      ? _buildFriendGroupedView(filtered, user)
                      : _buildListView(filtered),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.padding),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
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
      onTap: () => setState(() => _filterStatus = status),
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
          DropdownMenuItem(value: 'friend', child: Text('Friend')),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _sortBy = value);
        },
      ),
    );
  }

  Widget _buildListView(List<Challenge> challenges) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
      itemCount: challenges.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ChallengeCard(challenge: challenges[index]),
      ),
    );
  }

  Widget _buildFriendGroupedView(List<Challenge> challenges, User? currentUser) {
    final Map<String, List<Challenge>> grouped = {};
    final Map<String, dynamic> friendInfo = {};

    for (var c in challenges) {
      final other = c.creator.id == currentUser?.id ? c.recipient : c.creator;
      if (!grouped.containsKey(other.id)) {
        grouped[other.id] = [];
        friendInfo[other.id] = other;
      }
      grouped[other.id]!.add(c);
    }

    final sortedKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final friendId = sortedKeys[index];
        final friend = friendInfo[friendId];
        final friendChallenges = grouped[friendId]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  AvatarWidget(user: friend, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    friend.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.zinc400, letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  Text(
                    '${friendChallenges.length}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.zinc600, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ...friendChallenges.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChallengeCard(challenge: c, showParticipant: false),
            )),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.search, size: 48, color: AppTheme.zinc800),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No challenges found.' : 'No matches for "$_searchQuery"',
            style: const TextStyle(color: AppTheme.zinc600),
          ),
        ],
      ),
    );
  }
}
