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
import '../widgets/unified_search_field.dart';
import '../widgets/app_header.dart';
import '../widgets/form_label.dart';

class CreateChallengeScreen extends StatefulWidget {
  final User? recipient;
  const CreateChallengeScreen({super.key, this.recipient});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _friendSearchController = TextEditingController();
  
  String _deadline = 'today';
  String _proofType = 'code';
  bool _isLaunching = false;
  bool _isKeyboardOpen = false;
  
  final List<User> _selectedFriends = [];
  List<User> _filteredFriends = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.recipient != null) {
      _selectedFriends.add(widget.recipient!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriends();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _descController.dispose();
    _friendSearchController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) return;
    final view = View.maybeOf(context) ?? WidgetsBinding.instance.platformDispatcher.views.first;
    final double bottomInset = view.viewInsets.bottom;
    final bool isKeyboardOpen = bottomInset > 0;
    if (isKeyboardOpen != _isKeyboardOpen) {
      setState(() {
        _isKeyboardOpen = isKeyboardOpen;
      });
    }
  }

  Future<void> _loadFriends() async {
    final provider = context.read<FriendProvider>();
    if (provider.friends.isEmpty) {
      await provider.fetchFriends();
    }
    if (!mounted) return;
    setState(() {
      _filteredFriends = provider.friends;
    });
  }

  void _onSearchFriends(String query) {
    final allFriends = context.read<FriendProvider>().friends;
    if (!mounted) return;
    setState(() {
      _filteredFriends = allFriends.where((f) => 
        f.name.toLowerCase().contains(query.toLowerCase()) || 
        f.username.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final double bottomPadding = widget.recipient != null 
        ? 20.0 
        : (_isKeyboardOpen ? 20.0 : 120.0);

    return Scaffold(
      appBar: AppHeader(
        title: 'New Challenge',
        showBackButton: Navigator.canPop(context),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('RECIPIENTS'),
            _buildFriendSelection(),
            const SizedBox(height: 32),
            _buildLabel('CHALLENGE TITLE'),
            CustomTextField(controller: _titleController, hintText: 'e.g. Morning 5km Run'),
            const SizedBox(height: 24),
            _buildLabel('DETAILS'),
            CustomTextField(controller: _descController, hintText: 'Explain the rules...', maxLines: 4),
            const SizedBox(height: 32),
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
                          DropdownMenuItem(value: '3days', child: Text('3 Days')),
                          DropdownMenuItem(value: '1week', child: Text('1 Week')),
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
                          DropdownMenuItem(value: 'code', child: Text('Code')),
                          DropdownMenuItem(value: 'explanation', child: Text('Explanation')),
                          DropdownMenuItem(value: 'image', child: Text('Image')),
                          DropdownMenuItem(value: 'link', child: Text('Link')),
                          DropdownMenuItem(value: 'any', child: Text('Any')),
                        ],
                        onChanged: (val) => setState(() => _proofType = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            CustomButton(
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
                    'deadline': (() {
                      switch (_deadline) {
                        case 'today':
                          return DateTime.now().add(const Duration(hours: 12));
                        case 'tomorrow':
                          return DateTime.now().add(const Duration(days: 1));
                        case '3days':
                          return DateTime.now().add(const Duration(days: 3));
                        case '1week':
                          return DateTime.now().add(const Duration(days: 7));
                        default:
                          return DateTime.now().add(const Duration(days: 1));
                      }
                    })().toIso8601String(),
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
              backgroundColor: primaryColor,
              textColor: bgColor,
              icon: Icon(LucideIcons.rocket, size: 20, color: bgColor),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? AppTheme.zinc800 : AppTheme.zinc200).withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: isDark ? AppTheme.zinc950 : AppTheme.white,
          isExpanded: true,
          icon: Icon(LucideIcons.chevronDown, size: 16, color: Theme.of(context).textTheme.labelSmall?.color),
          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildFriendSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFriends.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedFriends.map((f) => Chip(
              backgroundColor: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
              side: BorderSide(color: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
              label: Text(f.name, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
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
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 18, color: Theme.of(context).textTheme.labelSmall?.color),
                const SizedBox(width: 12),
                Text(
                  _selectedFriends.isEmpty ? 'Select friends...' : 'Add more friends...',
                  style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFriendPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Friends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 20),
              UnifiedSearchField(
                controller: _friendSearchController,
                hintText: 'Search by name...',
                onChanged: (val) {
                  _onSearchFriends(val);
                  setModalState(() {});
                },
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
                      title: Text(friend.name, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
                      subtitle: Text('@${friend.username}', style: const TextStyle(color: AppTheme.zinc600, fontSize: 12)),
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : (isDark ? AppTheme.zinc800 : AppTheme.zinc200)),
                        ),
                        child: isSelected ? Icon(LucideIcons.check, size: 16, color: Theme.of(context).scaffoldBackgroundColor) : null,
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
                backgroundColor: Theme.of(context).primaryColor,
                textColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return FormLabel(
      label: text,
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
    );
  }
}
