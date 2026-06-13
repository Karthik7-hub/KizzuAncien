import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/friend_provider.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import 'create_challenge_screen.dart';
import 'truth_dare_screen.dart';
import 'friend_profile_screen.dart';

import '../widgets/app_header.dart';
import '../widgets/section_header.dart';

import '../widgets/unified_search_field.dart';
import '../widgets/unified_user_tile.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final Map<String, bool> _loadingStates = {};

  bool _isUserLoading(String id) => _loadingStates[id] ?? false;
  bool get _isAnyUserLoading => _loadingStates.values.any((v) => v);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final friendProvider = context.read<FriendProvider>();
      if (friendProvider.friends.isEmpty && 
          friendProvider.incomingRequests.isEmpty && 
          friendProvider.outgoingRequests.isEmpty) {
        friendProvider.fetchFriends();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      _debounce?.cancel();
      context.read<FriendProvider>().searchUsers('');
      return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<FriendProvider>().searchUsers(query);
      }
    });
  }

  Future<void> _onRefresh() async {
    await context.read<FriendProvider>().fetchFriends();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final friendProvider = context.watch<FriendProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppHeader(
        title: 'Friends',
        actions: [
          Icon(LucideIcons.userPlus, color: primaryColor, size: 22),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: isDark ? AppTheme.white : AppTheme.black,
        backgroundColor: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UnifiedSearchField(
                      controller: _searchController,
                      hintText: 'Find friends by name...',
                      onChanged: _onSearchChanged,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (provider.isLoading) {
      return SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
      );
    }

    if (provider.searchResults.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Text('No users found', style: TextStyle(color: isDark ? AppTheme.zinc500 : AppTheme.zinc600))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader('FRIENDS', provider.friends.length),
        ),
        if (provider.friends.isEmpty && !provider.isLoading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  'No connections yet.\nInvite your circle to join!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? AppTheme.zinc600 : AppTheme.zinc400, height: 1.5),
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
    return SectionHeader(
      title: title,
      count: count,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
    );
  }

  Widget _buildUserItem(User user, {required String type, String? requestId}) {
    final String? subtitle = type == 'incoming' ? 'Sent you a request' : 
                            type == 'outgoing' ? 'Request pending' : null;

    return UnifiedUserTile(
      user: user,
      variant: UserTileVariant.list,
      subtitle: subtitle,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: user))),
      trailing: _buildActions(user, type, requestId),
    );
  }

  Widget _buildActions(User user, String type, String? requestId) {
    final provider = context.read<FriendProvider>();
    final isProcessing = _isUserLoading(user.id) || (requestId != null && _isUserLoading(requestId));
    final isAnyLoading = _isAnyUserLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (type == 'search') {
      return IconButton(
        icon: isProcessing 
          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppTheme.white : AppTheme.black))
          : Icon(LucideIcons.userPlus, color: isDark ? AppTheme.white : AppTheme.zinc950, size: 20),
        style: IconButton.styleFrom(backgroundColor: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
        onPressed: isAnyLoading ? null : () async {
          setState(() => _loadingStates[user.id] = true);
          await provider.sendFriendRequest(user.id);
          if (mounted) {
            setState(() => _loadingStates[user.id] = false);
          }
        },
      );
    } else if (type == 'incoming' && requestId != null) {
      final rId = requestId;
      return Row(
        children: [
          IconButton(
            icon: isProcessing 
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppTheme.black : AppTheme.white))
              : Icon(LucideIcons.check, color: isDark ? AppTheme.black : AppTheme.white, size: 18),
            style: IconButton.styleFrom(backgroundColor: isDark ? AppTheme.white : AppTheme.black),
            onPressed: isAnyLoading ? null : () async {
              setState(() => _loadingStates[rId] = true);
              await provider.respondToRequest(rId, 'accepted');
              if (mounted) {
                setState(() => _loadingStates[rId] = false);
              }
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: isProcessing 
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppTheme.white : AppTheme.black))
              : Icon(LucideIcons.x, color: isDark ? AppTheme.white : AppTheme.zinc950, size: 18),
            style: IconButton.styleFrom(backgroundColor: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
            onPressed: isAnyLoading ? null : () async {
              setState(() => _loadingStates[rId] = true);
              await provider.respondToRequest(rId, 'rejected');
              if (mounted) {
                setState(() => _loadingStates[rId] = false);
              }
            },
          ),
        ],
      );
    } else if (type == 'outgoing' && requestId != null) {
      final rId = requestId;
      return TextButton(
        onPressed: isAnyLoading ? null : () async {
          setState(() => _loadingStates[rId] = true);
          await provider.cancelRequest(rId);
          if (mounted) {
            setState(() => _loadingStates[rId] = false);
          }
        },
        child: Text(
          isProcessing ? '...' : 'Cancel', 
          style: TextStyle(color: isDark ? AppTheme.zinc400 : AppTheme.zinc600, fontSize: 13, fontWeight: FontWeight.w600)
        ),
      );
    } else {
      return Row(
        children: [
          IconButton(
            onPressed: isAnyLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => TruthDareScreen(recipient: user))),
            icon: const Icon(LucideIcons.zap, color: Colors.amber, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppTheme.zinc900 : AppTheme.zinc100, 
              side: BorderSide(color: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isAnyLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateChallengeScreen(recipient: user))),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.white : AppTheme.black,
              foregroundColor: isDark ? AppTheme.black : AppTheme.white,
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
