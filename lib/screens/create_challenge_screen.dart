import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kizzu_ancien/models/user.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/widgets/custom_button.dart';
import 'package:kizzu_ancien/widgets/custom_text_field.dart';
import '../widgets/avatar_widget.dart';

import '../providers/navigation_provider.dart';
import '../providers/friend_provider.dart';

class CreateChallengeScreen extends StatefulWidget {
  final User? recipient;
  const CreateChallengeScreen({super.key, this.recipient});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _friendSearchController = TextEditingController();
  
  String _deadline = 'today';
  String _proofType = 'any';
  bool _isLaunching = false;
  
  final List<User> _selectedFriends = [];
  List<User> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    if (widget.recipient != null) {
      _selectedFriends.add(widget.recipient!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriends();
    });
  }

  Future<void> _loadFriends() async {
    final provider = context.read<FriendProvider>();
    if (provider.friends.isEmpty) {
      await provider.fetchFriends();
    }
    setState(() {
      _filteredFriends = provider.friends;
    });
  }

  void _onSearchFriends(String query) {
    final allFriends = context.read<FriendProvider>().friends;
    setState(() {
      _filteredFriends = allFriends.where((f) => 
        f.name.toLowerCase().contains(query.toLowerCase()) || 
        f.username.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Challenge',
          style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('RECIPIENTS'),
                  _buildFriendSelection(),
                  const SizedBox(height: 32),
                  _buildLabel('CHALLENGE TITLE'),
                  CustomTextField(controller: _titleController, hintText: 'e.g. Morning 5km Run'),
                  const SizedBox(height: 20),
                  _buildLabel('DETAILS'),
                  CustomTextField(controller: _descController, hintText: 'Explain the rules...', maxLines: 4),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('DEADLINE'),
                            _buildDropdown(
                              value: _deadline,
                              items: const [
                                DropdownMenuItem(value: 'today', child: Text('Today')),
                                DropdownMenuItem(value: 'tomorrow', child: Text('Tomorrow')),
                              ],
                              onChanged: (val) => setState(() => _deadline = val!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('PROOF TYPE'),
                            _buildDropdown(
                              value: _proofType,
                              items: const [
                                DropdownMenuItem(value: 'any', child: Text('Any')),
                                DropdownMenuItem(value: 'image', child: Text('Photo')),
                                DropdownMenuItem(value: 'video', child: Text('Video')),
                                DropdownMenuItem(value: 'text', child: Text('Text')),
                              ],
                              onChanged: (val) => setState(() => _proofType = val!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.black.withValues(alpha: 0), AppTheme.black],
              ),
            ),
            child: CustomButton(
              text: 'Launch Challenge',
              isLoading: _isLaunching,
              onPressed: () async {
                if (_selectedFriends.isEmpty || _isLaunching || _titleController.text.isEmpty) return;
                setState(() => _isLaunching = true);
                
                final challengeProvider = context.read<ChallengeProvider>();
                final navProvider = context.read<NavigationProvider>();

                bool allSuccess = true;
                for (var friend in _selectedFriends) {
                  final success = await challengeProvider.createChallenge({
                    'recipientId': friend.id,
                    'title': _titleController.text.trim(),
                    'description': _descController.text.trim(),
                    'deadline': _deadline == 'today' 
                        ? DateTime.now().add(const Duration(hours: 12)).toIso8601String()
                        : DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                    'proofType': _proofType,
                  });
                  if (!success) allSuccess = false;
                }
                
                if (!context.mounted) return;
                if (allSuccess) {
                  if (widget.recipient != null) {
                    Navigator.of(context).pop();
                  } else {
                    navProvider.setIndex(0);
                    _titleController.clear();
                    _descController.clear();
                    _selectedFriends.clear();
                  }
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Some challenges failed to launch.'), backgroundColor: Colors.redAccent)
                  );
                }
                setState(() => _isLaunching = false);
              },
              backgroundColor: AppTheme.white,
              textColor: AppTheme.black,
              icon: const Icon(LucideIcons.rocket, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFriends.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedFriends.map((f) => Chip(
              backgroundColor: AppTheme.zinc900,
              side: const BorderSide(color: AppTheme.zinc800),
              label: Text(f.name, style: const TextStyle(color: AppTheme.white, fontSize: 12)),
              deleteIcon: const Icon(LucideIcons.x, size: 14, color: AppTheme.zinc500),
              onDeleted: () => setState(() => _selectedFriends.remove(f)),
              avatar: AvatarWidget(user: f, size: 20, showBorder: false),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            )).toList(),
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          onTap: () => _showFriendPicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.zinc950,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.zinc900),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.search, size: 18, color: AppTheme.zinc700),
                const SizedBox(width: 12),
                Text(
                  _selectedFriends.isEmpty ? 'Select friends...' : 'Add more friends...',
                  style: const TextStyle(color: AppTheme.zinc700, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFriendPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.zinc950,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Friends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.white)),
              const SizedBox(height: 20),
              TextField(
                controller: _friendSearchController,
                onChanged: (val) {
                  _onSearchFriends(val);
                  setModalState(() {});
                },
                style: const TextStyle(color: AppTheme.white),
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  fillColor: AppTheme.zinc900,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredFriends.length,
                  itemBuilder: (context, index) {
                    final friend = _filteredFriends[index];
                    final isSelected = _selectedFriends.any((f) => f.id == friend.id);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: AvatarWidget(user: friend, size: 40, showBorder: false),
                      title: Text(friend.name, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600)),
                      subtitle: Text('@${friend.username}', style: const TextStyle(color: AppTheme.zinc600, fontSize: 12)),
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppTheme.white : Colors.transparent,
                          border: Border.all(color: isSelected ? AppTheme.white : AppTheme.zinc800),
                        ),
                        child: isSelected ? const Icon(LucideIcons.check, size: 16, color: AppTheme.black) : null,
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedFriends.removeWhere((f) => f.id == friend.id);
                          } else {
                            _selectedFriends.add(friend);
                          }
                        });
                        setModalState(() {});
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Done',
                onPressed: () => Navigator.pop(context),
                backgroundColor: AppTheme.white,
                textColor: AppTheme.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.zinc600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.zinc900,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.zinc800.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppTheme.zinc900,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppTheme.zinc500),
          style: const TextStyle(color: AppTheme.white, fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Future<User?> _showRecipientPicker(BuildContext context) async {
    final friendProvider = context.read<FriendProvider>();
    if (friendProvider.friends.isEmpty) {
      await friendProvider.fetchFriends();
    }

    return await showModalBottomSheet<User>(
      context: context,
      backgroundColor: AppTheme.zinc950,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Challenge a friend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.white)),
            const SizedBox(height: 16),
            if (friendProvider.friends.isEmpty)
              const Center(child: Text('No friends found. Add some first!', style: TextStyle(color: AppTheme.zinc600)))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: friendProvider.friends.length,
                  itemBuilder: (context, index) {
                    final friend = friendProvider.friends[index];
                    return ListTile(
                      leading: AvatarWidget(user: friend, size: 32, showBorder: false),
                      title: Text(friend.name, style: const TextStyle(color: AppTheme.white)),
                      onTap: () => Navigator.pop(context, friend),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
