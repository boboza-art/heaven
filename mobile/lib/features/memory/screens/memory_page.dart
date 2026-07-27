import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../memory/controllers/memory_controller.dart';
import '../memory/models/memory_model.dart';

/// Memory management page.
///
/// Two tabs:
/// - 待审 — AI-extracted memories not yet approved
/// - 已保存 — Approved memories that AI uses as context
///
/// Users can: approve, edit, delete memories, and manually add new ones.
class MemoryPage extends ConsumerStatefulWidget {
  const MemoryPage({super.key});

  @override
  ConsumerState<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends ConsumerState<MemoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(memoryControllerProvider.notifier).loadMemories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryControllerProvider);

    return Scaffold(
      backgroundColor: HavenColors.background,
      appBar: AppBar(
        backgroundColor: HavenColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: HavenColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '我的记忆',
          style: HavenTypography.heading.copyWith(
            color: HavenColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: HavenColors.primary),
            onPressed: () => _showAddDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: HavenColors.primary,
          unselectedLabelColor: HavenColors.textSecondary,
          indicatorColor: HavenColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: HavenTypography.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: HavenTypography.body,
          tabs: [
            Tab(text: '待审 (${state.pendingCount})'),
            Tab(text: '已保存 (${state.approvedCount})'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: HavenColors.primary,
                strokeWidth: 2,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _MemoryList(
                  memories: state.pendingMemories,
                  emptyMessage: '没有待审核的记忆',
                  emptyHint: 'AI 从对话中提取的新记忆会出现在这里',
                  isPending: true,
                ),
                _MemoryList(
                  memories: state.approvedMemories,
                  emptyMessage: '还没有已保存的记忆',
                  emptyHint: '和 AI 聊天后，它会慢慢记住关于你的事',
                  isPending: false,
                ),
              ],
            ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AddMemoryDialog(),
    );
  }
}

/// Reusable memory list with empty state.
class _MemoryList extends ConsumerWidget {
  final List<MemoryModel> memories;
  final String emptyMessage;
  final String emptyHint;
  final bool isPending;

  const _MemoryList({
    required this.memories,
    required this.emptyMessage,
    required this.emptyHint,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (memories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(HavenSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 48,
                color: HavenColors.textSecondary.withAlpha(80),
              ),
              const SizedBox(height: HavenSpacing.md),
              Text(
                emptyMessage,
                style: HavenTypography.body.copyWith(
                  color: HavenColors.textSecondary,
                ),
              ),
              const SizedBox(height: HavenSpacing.sm),
              Text(
                emptyHint,
                style: HavenTypography.caption.copyWith(
                  color: HavenColors.textSecondary.withAlpha(120),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: HavenColors.primary,
      onRefresh: () =>
          ref.read(memoryControllerProvider.notifier).loadMemories(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: HavenSpacing.lg,
          vertical: HavenSpacing.md,
        ),
        itemCount: memories.length,
        itemBuilder: (context, index) {
          return _MemoryCard(
            memory: memories[index],
            isPending: isPending,
          );
        },
      ),
    );
  }
}

/// A single memory card with action buttons.
class _MemoryCard extends ConsumerWidget {
  final MemoryModel memory;
  final bool isPending;

  const _MemoryCard({
    required this.memory,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoryControllerProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: HavenSpacing.sm),
      padding: const EdgeInsets.all(HavenSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isPending
            ? Border.all(color: HavenColors.moodOkay.withAlpha(60), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: HavenSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _categoryColor(memory.category).withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  memory.categoryLabel,
                  style: HavenTypography.caption.copyWith(
                    color: _categoryColor(memory.category),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(memory.createdAt),
                style: HavenTypography.caption.copyWith(
                  color: HavenColors.textSecondary.withAlpha(100),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: HavenSpacing.sm),

          // Content
          Text(
            memory.content,
            style: HavenTypography.body.copyWith(
              color: HavenColors.textPrimary,
              height: 1.5,
            ),
          ),

          // Actions
          const SizedBox(height: HavenSpacing.sm),
          Row(
            children: [
              if (isPending)
                _ActionButton(
                  icon: Icons.check_rounded,
                  label: '采纳',
                  color: HavenColors.primary,
                  isLoading: state.isProcessing,
                  onTap: () => _confirmApprove(context, ref),
                )
              else
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: '编辑',
                  color: HavenColors.textSecondary,
                  isLoading: state.isProcessing,
                  onTap: () => _showEditDialog(context, ref),
                ),
              const SizedBox(width: HavenSpacing.sm),
              _ActionButton(
                icon: Icons.delete_outline,
                label: '删除',
                color: HavenColors.moodLow,
                isLoading: state.isProcessing,
                onTap: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmApprove(BuildContext context, WidgetRef ref) {
    ref.read(memoryControllerProvider.notifier).approveMemory(memory.id);
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _EditMemoryDialog(memory: memory),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '删除这条记忆？',
          style: HavenTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: HavenColors.textPrimary,
          ),
        ),
        content: Text(
          '删除后 AI 将不再记住这条信息。',
          style: HavenTypography.caption.copyWith(
            color: HavenColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              '取消',
              style: HavenTypography.caption.copyWith(
                color: HavenColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(memoryControllerProvider.notifier)
                  .deleteMemory(memory.id);
            },
            child: Text(
              '删除',
              style: HavenTypography.caption.copyWith(
                color: HavenColors.moodBad,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'situation':
        return HavenColors.moodGood;
      case 'preference':
        return HavenColors.secondary;
      case 'concern':
        return HavenColors.moodOkay;
      case 'pattern':
        return HavenColors.moodLow;
      case 'event':
        return HavenColors.primary;
      case 'coping':
        return HavenColors.moodGreat;
      default:
        return HavenColors.textSecondary;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }
}

/// Small action button used inside memory cards.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HavenSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: HavenTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for adding a new memory manually.
class _AddMemoryDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddMemoryDialog> createState() => _AddMemoryDialogState();
}

class _AddMemoryDialogState extends ConsumerState<_AddMemoryDialog> {
  String _selectedCategory = 'situation';
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryControllerProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        '添加记忆',
        style: HavenTypography.body.copyWith(
          fontWeight: FontWeight.w600,
          color: HavenColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '分类',
              style: HavenTypography.caption.copyWith(
                color: HavenColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: HavenSpacing.xs),
            _CategoryPicker(
              selected: _selectedCategory,
              onChanged: (c) => setState(() => _selectedCategory = c),
            ),
            const SizedBox(height: HavenSpacing.md),
            Text(
              '内容',
              style: HavenTypography.caption.copyWith(
                color: HavenColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: HavenSpacing.xs),
            TextField(
              controller: _contentController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'AI 会记住这些信息...',
                hintStyle: HavenTypography.caption.copyWith(
                  color: HavenColors.textSecondary.withAlpha(80),
                ),
                filled: true,
                fillColor: HavenColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(HavenSpacing.sm),
              ),
              style: HavenTypography.body.copyWith(
                color: HavenColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isProcessing
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(
            '取消',
            style: HavenTypography.caption.copyWith(
              color: HavenColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: state.isProcessing ? null : () => _submit(context),
          child: state.isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: HavenColors.primary,
                  ),
                )
              : Text(
                  '添加',
                  style: HavenTypography.caption.copyWith(
                    color: HavenColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final success = await ref.read(memoryControllerProvider.notifier).addMemory(
          category: _selectedCategory,
          content: content,
        );

    if (mounted && success) {
      Navigator.of(context).pop();
    }
  }
}

/// Dialog for editing a memory's content and category.
class _EditMemoryDialog extends ConsumerStatefulWidget {
  final MemoryModel memory;

  const _EditMemoryDialog({required this.memory});

  @override
  ConsumerState<_EditMemoryDialog> createState() => _EditMemoryDialogState();
}

class _EditMemoryDialogState extends ConsumerState<_EditMemoryDialog> {
  late String _selectedCategory;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.memory.category;
    _contentController = TextEditingController(text: widget.memory.content);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryControllerProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        '编辑记忆',
        style: HavenTypography.body.copyWith(
          fontWeight: FontWeight.w600,
          color: HavenColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '分类',
              style: HavenTypography.caption.copyWith(
                color: HavenColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: HavenSpacing.xs),
            _CategoryPicker(
              selected: _selectedCategory,
              onChanged: (c) => setState(() => _selectedCategory = c),
            ),
            const SizedBox(height: HavenSpacing.md),
            Text(
              '内容',
              style: HavenTypography.caption.copyWith(
                color: HavenColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: HavenSpacing.xs),
            TextField(
              controller: _contentController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                filled: true,
                fillColor: HavenColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(HavenSpacing.sm),
              ),
              style: HavenTypography.body.copyWith(
                color: HavenColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isProcessing
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(
            '取消',
            style: HavenTypography.caption.copyWith(
              color: HavenColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: state.isProcessing ? null : () => _submit(context),
          child: state.isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: HavenColors.primary,
                  ),
                )
              : Text(
                  '保存',
                  style: HavenTypography.caption.copyWith(
                    color: HavenColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final success = await ref.read(memoryControllerProvider.notifier).editMemory(
          widget.memory.id,
          content: content,
          category: _selectedCategory,
        );

    if (mounted && success) {
      Navigator.of(context).pop();
    }
  }
}

/// Horizontal scrollable category picker.
class _CategoryPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryPicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: MemoryModel.allCategories.map((cat) {
        final isSelected = cat == selected;
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: HavenSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? HavenColors.primary.withAlpha(20)
                  : HavenColors.background,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: HavenColors.primary.withAlpha(60))
                  : null,
            ),
            child: Text(
              _categoryLabel(cat),
              style: HavenTypography.caption.copyWith(
                color: isSelected
                    ? HavenColors.primary
                    : HavenColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'situation':
        return '生活状况';
      case 'preference':
        return '个人偏好';
      case 'concern':
        return '当前担忧';
      case 'pattern':
        return '行为模式';
      case 'event':
        return '发生事件';
      case 'coping':
        return '应对方式';
      default:
        return cat;
    }
  }
}
