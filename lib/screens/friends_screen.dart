import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/friend_provider.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import '../widgets/avatar_widget.dart';
import 'create_challenge_screen.dart';
import 'truth_dare_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().fetchFriends();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<FriendProvider>().fetchFriends();
  }

  @override
  Widget build(BuildContext context) {
    final friendProvider = context.watch<FriendProvider>();

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.white,
        backgroundColor: AppTheme.zinc900,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Community',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => friendProvider.searchUsers(val),
                      style: const TextStyle(color: AppTheme.white),
                      decoration: InputDecoration(
                        hintText: 'Find friends by name...',
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
                  ],
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              _buildSearchSection(friendProvider)
            else ...[
              _buildIncomingRequestsSection(friendProvider),
              _buildFriendsSection(friendProvider),
              _buildOutgoingRequestsSection(friendProvider),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(FriendProvider provider) {
    if (provider.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2)),
      );
    }

    if (provider.searchResults.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No users found', style: TextStyle(color: AppTheme.zinc600))),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = provider.searchResults[index];
            return _buildUserItem(user, type: 'search');
          },
          childCount: provider.searchResults.length,
        ),
      ),
    );
  }

  Widget _buildIncomingRequestsSection(FriendProvider provider) {
    if (provider.incomingRequests.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader('REQUESTS', provider.incomingRequests.length),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final req = provider.incomingRequests[index];
                return _buildUserItem(req['user'], type: 'incoming', requestId: req['id']);
              },
              childCount: provider.incomingRequests.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutgoingRequestsSection(FriendProvider provider) {
    if (provider.outgoingRequests.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader('PENDING', provider.outgoingRequests.length),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final req = provider.outgoingRequests[index];
                return _buildUserItem(req['user'], type: 'outgoing', requestId: req['id']);
              },
              childCount: provider.outgoingRequests.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsSection(FriendProvider provider) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader('FRIENDS', provider.friends.length),
        ),
        if (provider.friends.isEmpty && !provider.isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  'No connections yet.\nInvite your circle to join!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.zinc700, height: 1.5),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = provider.friends[index];
                  return _buildUserItem(user, type: 'friend');
                },
                childCount: provider.friends.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.zinc500,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.zinc900,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(fontSize: 10, color: AppTheme.zinc400, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(User user, {required String type, String? requestId}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.zinc900.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Row(
        children: [
          AvatarWidget(user: user, size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                Text(
                  '@${user.username}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.zinc500),
                ),
              ],
            ),
          ),
          _buildActions(user, type, requestId),
        ],
      ),
    );
  }

  Widget _buildActions(User user, String type, String? requestId) {
    final provider = context.read<FriendProvider>();

    if (type == 'search') {
      return IconButton(
        icon: const Icon(LucideIcons.userPlus, color: AppTheme.white, size: 20),
        style: IconButton.styleFrom(backgroundColor: AppTheme.zinc800),
        onPressed: () => provider.sendFriendRequest(user.id),
      );
    } else if (type == 'incoming') {
      return Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.check, color: AppTheme.black, size: 18),
            style: IconButton.styleFrom(backgroundColor: AppTheme.white),
            onPressed: () => provider.respondToRequest(requestId!, 'accepted'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.x, color: AppTheme.white, size: 18),
            style: IconButton.styleFrom(backgroundColor: AppTheme.zinc800),
            onPressed: () => provider.respondToRequest(requestId!, 'rejected'),
          ),
        ],
      );
    } else if (type == 'outgoing') {
      return TextButton(
        onPressed: () => provider.cancelRequest(requestId!),
        child: const Text('Cancel', style: TextStyle(color: AppTheme.zinc600, fontSize: 13, fontWeight: FontWeight.w600)),
      );
    } else {
      return Row(
        children: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TruthDareScreen(recipient: user))),
            icon: const Icon(LucideIcons.zap, color: Colors.amber, size: 18),
            style: IconButton.styleFrom(backgroundColor: AppTheme.zinc900, side: const BorderSide(color: AppTheme.zinc800)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateChallengeScreen(recipient: user))),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.white,
              foregroundColor: AppTheme.black,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Challenge', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
  }
}
