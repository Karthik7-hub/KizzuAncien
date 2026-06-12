import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kizzu_ancien/models/user.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/widgets/custom_button.dart';
import 'package:kizzu_ancien/widgets/keyboard_spacer.dart';
import '../widgets/avatar_widget.dart';
import '../providers/navigation_provider.dart';
import '../providers/friend_provider.dart';

class CreateChallengeScreen extends StatefulWidget {
  final User? recipient;
  const CreateChallengeScreen({super.key, this.recipient});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
    
    // Root Cause #1 Fix: Listen to input changes to refresh UI state
    _titleController.addListener(() => setState(() {}));
    
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
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: Navigator.canPop(context) 
          ? IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
            )
          : null,
        title: const Text(
          'NEW CHALLENGE',
          style: TextStyle(color: AppTheme.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('RECIPIENTS', LucideIcons.users),
                  const SizedBox(height: 16),
                  _buildFriendSelection(),
                  const SizedBox(height: 40),
                  
                  _buildSectionHeader('CHALLENGE INFO', LucideIcons.edit3),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _titleController, 
                    hint: 'e.g. 100 Pushups Daily',
                    label: 'TITLE',
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descController, 
                    hint: 'Describe the rules or goals...',
                    label: 'DESCRIPTION',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 40),
                  
                  _buildSectionHeader('CONFIGURATION', LucideIcons.settings),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildConfigItem(
                          label: 'DEADLINE',
                          child: _buildDropdown(
                            value: _deadline,
                            items: const [
                              DropdownMenuItem(value: 'today', child: Text('Today')),
                              DropdownMenuItem(value: 'tomorrow', child: Text('Tomorrow')),
                              DropdownMenuItem(value: '3days', child: Text('3 Days')),
                              DropdownMenuItem(value: 'week', child: Text('1 Week')),
                            ],
                            onChanged: (val) => setState(() => _deadline = val!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildConfigItem(
                          label: 'PROOF TYPE',
                          child: _buildDropdown(
                            value: _proofType,
                            items: const [
                              DropdownMenuItem(value: 'any', child: Text('Any')),
                              DropdownMenuItem(value: 'image', child: Text('Photo')),
                              DropdownMenuItem(value: 'code', child: Text('Code')),
                              DropdownMenuItem(value: 'link', child: Text('Link')),
                            ],
                            onChanged: (val) => setState(() => _proofType = val!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
          const IsolatedKeyboardSpacer(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.zinc600),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required String label, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.zinc950,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.zinc900),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: AppTheme.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.zinc800, fontSize: 14),
              contentPadding: const EdgeInsets.all(20),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigItem({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: const BoxDecoration(
        color: AppTheme.black,
        border: Border(top: BorderSide(color: AppTheme.zinc900)),
      ),
      child: CustomButton(
        text: 'LAUNCH CHALLENGE',
        isLoading: _isLaunching,
        onPressed: _titleController.text.isEmpty || _selectedFriends.isEmpty ? null : _handleLaunch,
        backgroundColor: AppTheme.white,
        textColor: AppTheme.black,
        icon: const Icon(LucideIcons.rocket, size: 18),
      ),
    );
  }

  void _handleLaunch() async {
    if (_selectedFriends.isEmpty || _isLaunching || _titleController.text.trim().isEmpty) return;
    setState(() => _isLaunching = true);
    
    final challengeProvider = context.read<ChallengeProvider>();
    final navProvider = context.read<NavigationProvider>();

    bool allSuccess = true;
    try {
      for (var friend in _selectedFriends) {
        final success = await challengeProvider.createChallenge({
          'recipientId': friend.id,
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'deadline': _calculateDeadline(),
          'proofType': _proofType,
        });
        if (!success) allSuccess = false;
      }
      
      if (!mounted) return;
      if (allSuccess) {
        if (mounted) {
          if (Navigator.canPop(context)) {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          } else {
            FocusScope.of(context).unfocus();
            navProvider.setIndex(0);
            _titleController.clear();
            _descController.clear();
            _selectedFriends.clear();
          }
        }
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to launch some challenges.'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  String _calculateDeadline() {
    DateTime now = DateTime.now();
    switch (_deadline) {
      case 'tomorrow': return now.add(const Duration(days: 1)).toIso8601String();
      case '3days': return now.add(const Duration(days: 3)).toIso8601String();
      case 'week': return now.add(const Duration(days: 7)).toIso8601String();
      default: return now.add(const Duration(hours: 12)).toIso8601String();
    }
  }

  Widget _buildFriendSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showFriendPicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.zinc950,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.zinc900),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.plusCircle, size: 20, color: AppTheme.white),
                const SizedBox(width: 16),
                Text(
                  _selectedFriends.isEmpty ? 'Tap to select recipients' : '${_selectedFriends.length} friends selected',
                  style: TextStyle(
                    color: _selectedFriends.isEmpty ? AppTheme.zinc700 : AppTheme.white, 
                    fontSize: 14,
                    fontWeight: _selectedFriends.isEmpty ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.zinc800),
              ],
            ),
          ),
        ),
        if (_selectedFriends.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFriends.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final f = _selectedFriends[index];
                return Container(
                  padding: const EdgeInsets.only(left: 4, right: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.zinc900,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.zinc800),
                  ),
                  child: Row(
                    children: [
                      AvatarWidget(user: f, size: 36, showBorder: false),
                      const SizedBox(width: 8),
                      Text(f.name.split(' ')[0], style: const TextStyle(color: AppTheme.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFriends.removeAt(index)),
                        child: const Icon(LucideIcons.x, size: 14, color: AppTheme.zinc600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) => Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SELECT FRIENDS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500, letterSpacing: 1.5)),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: AppTheme.zinc700, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
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
                    hintStyle: const TextStyle(color: AppTheme.zinc800),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppTheme.zinc700),
                    filled: true,
                    fillColor: AppTheme.zinc900,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = _filteredFriends[index];
                      final isSelected = _selectedFriends.any((f) => f.id == friend.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
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
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.zinc900 : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                AvatarWidget(user: friend, size: 40, showBorder: false),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(friend.name, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('@${friend.username}', style: const TextStyle(color: AppTheme.zinc700, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? AppTheme.white : Colors.transparent,
                                    border: Border.all(color: isSelected ? AppTheme.white : AppTheme.zinc800),
                                  ),
                                  child: isSelected ? const Icon(LucideIcons.check, size: 14, color: AppTheme.black) : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: CustomButton(
                    text: 'DONE',
                    onPressed: () {
                      // Root Cause #1 Fix: Sync parent state when closing picker
                      Navigator.pop(context);
                      setState(() {});
                    },
                    backgroundColor: AppTheme.white,
                    textColor: AppTheme.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.zinc900),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppTheme.zinc900,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppTheme.zinc500),
          style: const TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
