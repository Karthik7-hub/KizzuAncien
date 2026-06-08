import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/custom_button.dart';
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

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.history, size: 48, color: AppTheme.zinc800),
            const SizedBox(height: 16),
            Text('No shared history yet.', style: TextStyle(color: AppTheme.zinc600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.padding),
      itemCount: _history.length,
      itemBuilder: (context, index) => _buildChallengeCard(_history[index]),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final bool isCreator = challenge.creator.id != widget.friend.id;
    final String status = challenge.status.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.zinc900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description ?? 'No description provided.',
                      style: TextStyle(color: AppTheme.zinc500, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(challenge.status),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildDetailRow('Created', DateFormat('MMM d, yyyy').format(challenge.deadline.subtract(const Duration(days: 1)))),
          if (challenge.status == 'approved' || challenge.status == 'submitted')
            _buildDetailRow('Status', challenge.status == 'approved' ? 'Completed' : 'Pending Review'),
          
          if (challenge.submission != null) ...[
            const SizedBox(height: 16),
            const Text(
              'PROOF SUBMITTED',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.zinc900),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.submission!['proofUrl'] != null ? 'Media evidence uploaded' : 'Text verification',
                    style: const TextStyle(color: AppTheme.zinc300, fontSize: 13),
                  ),
                  if (challenge.submission!['proofText'] != null && challenge.submission!['proofText'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Note: ${challenge.submission!['proofText']}',
                      style: const TextStyle(color: AppTheme.zinc500, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.zinc600, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color textColor = AppTheme.zinc400;
    Color bgColor = AppTheme.zinc900;
    
    if (status == 'approved') {
      textColor = Colors.white;
      bgColor = Colors.green.withValues(alpha: 0.2);
    } else if (status == 'pending') {
      textColor = Colors.white;
      bgColor = Colors.blue.withValues(alpha: 0.2);
    } else if (status == 'rejected') {
      textColor = Colors.white;
      bgColor = Colors.red.withValues(alpha: 0.2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status == 'approved' ? 'COMPLETED' : status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0.5),
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
