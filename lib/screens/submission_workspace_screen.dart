import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../models/note.dart';
import '../providers/challenge_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/note_preview_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/section_header.dart';
import 'create_note_screen.dart';
import 'note_viewer_screen.dart';
import 'submission_screen.dart';

class SubmissionWorkspaceScreen extends StatefulWidget {
  final Challenge challenge;
  const SubmissionWorkspaceScreen({super.key, required this.challenge});

  @override
  State<SubmissionWorkspaceScreen> createState() => _SubmissionWorkspaceScreenState();
}

class _SubmissionWorkspaceScreenState extends State<SubmissionWorkspaceScreen> {
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().fetchNotes(widget.challenge.id);
    });
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final challengeProvider = context.read<ChallengeProvider>();
    final notes = List<Note>.from(challengeProvider.challengeNotes[widget.challenge.id] ?? []);
    final item = notes.removeAt(oldIndex);
    notes.insert(newIndex, item);
    
    challengeProvider.reorderNotes(widget.challenge.id, notes);
  }

  void _confirmDelete(Note note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Delete Note',
          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${note.title}"? This action cannot be undone.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? AppTheme.zinc500 : AppTheme.zinc600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<ChallengeProvider>();
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              navigator.pop(); // close dialog
              final success = await provider.deleteNote(widget.challenge.id, note.id);
              if (!success && mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Failed to delete note. Please try again.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddNotePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to Workspace',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: Theme.of(context).primaryColor
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNoteTypeOption(context, LucideIcons.code, 'Code', NoteType.code),
                _buildNoteTypeOption(context, LucideIcons.fileText, 'Explain', NoteType.explanation),
                _buildNoteTypeOption(context, LucideIcons.image, 'Image', NoteType.image),
                _buildNoteTypeOption(context, LucideIcons.link, 'Link', NoteType.link),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteTypeOption(BuildContext context, IconData icon, String label, NoteType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // close sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateNoteScreen(
              challengeId: widget.challenge.id,
              initialType: type,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
              shape: BoxShape.circle,
              border: isDark ? null : Border.all(color: AppTheme.zinc200),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).textTheme.bodyMedium?.color
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = context.watch<ChallengeProvider>();
    final user = context.watch<AuthProvider>().user;
    
    final currentChallenge = challengeProvider.challenges.firstWhere(
      (c) => c.id == widget.challenge.id,
      orElse: () => widget.challenge,
    );

    final notes = challengeProvider.challengeNotes[currentChallenge.id] ?? [];
    final bool isRecipient = user != null && currentChallenge.recipient.id == user.id;
    
    // Split notes by author
    final creatorNotes = notes.where((n) => n.createdBy.id == currentChallenge.creator.id).toList();
    final recipientNotes = notes.where((n) => n.createdBy.id == currentChallenge.recipient.id).toList();

    return Scaffold(
      appBar: AppHeader(
        title: 'Workspace',
        showBackButton: true,
        actions: [
          if (notes.isNotEmpty)
            IconButton(
              icon: Icon(
                _isReordering ? LucideIcons.check : LucideIcons.layers, 
                color: _isReordering ? Colors.greenAccent : Theme.of(context).primaryColor
              ),
              onPressed: () => setState(() => _isReordering = !_isReordering),
              tooltip: 'Reorder Notes',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildParticipantsHeader(currentChallenge),
          Expanded(
            child: notes.isEmpty
                ? const EmptyState(
                    icon: LucideIcons.layers,
                    title: 'Workspace is empty',
                    subtitle: 'Add code templates, images, and explanations to collaborate.',
                  )
                : _isReordering
                    ? _buildReorderableList(notes)
                    : _buildSplitWorkspaceLists(creatorNotes, recipientNotes, user?.id),
          ),
          _buildWorkspaceActionArea(currentChallenge, isRecipient),
        ],
      ),
    );
  }

  Widget _buildParticipantsHeader(Challenge challenge) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(bottom: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challenge.title,
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).primaryColor
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildParticipantChip('Creator', challenge.creator),
              const SizedBox(width: 16),
              _buildParticipantChip('Recipient', challenge.recipient),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantChip(String label, dynamic user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.zinc900.withValues(alpha: 0.5) : AppTheme.zinc100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.zinc800 : AppTheme.zinc200, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarWidget(user: user, size: 16, showBorder: false),
          const SizedBox(width: 6),
          Text(
            '$label: ${user.name}',
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).textTheme.bodyMedium?.color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitWorkspaceLists(List<Note> creatorNotes, List<Note> recipientNotes, String? currentUserId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (creatorNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionHeader(title: "CREATOR'S NOTES"),
            const SizedBox(height: 8),
            _buildNotesGrid(creatorNotes, currentUserId),
          ],
          if (recipientNotes.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeader(title: "RECIPIENT'S NOTES"),
            const SizedBox(height: 8),
            _buildNotesGrid(recipientNotes, currentUserId),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesGrid(List<Note> list, String? currentUserId) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final note = list[index];
        final bool canEdit = note.createdBy.id == currentUserId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NotePreviewCard(
            note: note,
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => NoteViewerScreen(note: note))
            ),
            trailing: _buildNoteOptionsButton(note, canEdit),
          ),
        );
      },
    );
  }

  Widget _buildNoteOptionsButton(Note note, bool canEdit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<String>(
      icon: Icon(
        LucideIcons.moreVertical, 
        color: isDark ? AppTheme.zinc600 : AppTheme.zinc400,
        size: 18,
      ),
      color: isDark ? AppTheme.zinc950 : AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
      ),
      onSelected: (action) {
        if (action == 'open') {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => NoteViewerScreen(note: note))
          );
        } else if (action == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateNoteScreen(
                challengeId: widget.challenge.id,
                noteToEdit: note,
              ),
            ),
          );
        } else if (action == 'delete') {
          _confirmDelete(note);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              Icon(LucideIcons.eye, size: 14, color: isDark ? AppTheme.zinc400 : AppTheme.zinc600),
              const SizedBox(width: 10),
              const Text('Open Note', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        if (canEdit) ...[
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(LucideIcons.edit2, size: 14, color: Theme.of(context).primaryColor),
                const SizedBox(width: 10),
                const Text('Edit Note', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('Delete Note', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReorderableList(List<Note> list) {
    return ReorderableListView(
      padding: const EdgeInsets.all(20),
      onReorder: _handleReorder,
      children: list.map((note) => Container(
        key: ValueKey(note.id),
        margin: const EdgeInsets.only(bottom: 12),
        child: NotePreviewCard(
          note: note,
          onTap: () {},
        ),
      )).toList(),
    );
  }

  Widget _buildWorkspaceActionArea(Challenge challenge, bool isRecipient) {
    final bool showSubmissionAction = isRecipient && (challenge.status == 'pending' || challenge.status == 'rejected');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: showSubmissionAction ? 2 : 1,
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _showAddNotePicker,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            if (showSubmissionAction) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => SubmissionScreen(challenge: challenge))
                    ),
                    icon: const Icon(LucideIcons.checkSquare, size: 16),
                    label: const Text('Create Submission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
