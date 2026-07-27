import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// Chat page — AI companion conversation.
///
/// The core experience: user speaks, AI listens and responds
/// with empathy, never diagnosis, never pressure.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatControllerProvider.notifier).showWelcome();
    });
    // Scroll to bottom when keyboard opens
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatControllerProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);

    // Auto-scroll when new messages arrive (listen to message count changes)
    ref.listen<int>(
      chatControllerProvider.select((s) => s.messages.length),
      (prev, next) {
        if (next > (prev ?? 0)) {
          _scrollToBottom();
        }
      },
    );

    return Scaffold(
      backgroundColor: HavenColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: HavenColors.textSecondary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: HavenColors.secondary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                '伴',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HavenColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: HavenSpacing.sm),
            Text(
              '陪伴者',
              style: HavenTypography.body.copyWith(
                color: HavenColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child: state.messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        top: HavenSpacing.md,
                        bottom: HavenSpacing.sm,
                      ),
                      itemCount: state.messages.length +
                          (state.isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length &&
                            state.isSending) {
                          return _buildTypingBubble();
                        }
                        return ChatBubble(
                          message: state.messages[index],
                        );
                      },
                    ),
            ),

            // Error banner
            if (state.errorMessage != null) _buildErrorBanner(state.errorMessage!),

            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HavenSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: HavenColors.secondary.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text('💬', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: HavenSpacing.md),
            Text(
              '和陪伴者聊一聊',
              style: HavenTypography.body.copyWith(
                color: HavenColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: HavenSpacing.xs,
        horizontal: HavenSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: HavenColors.secondary.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              '伴',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HavenColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: HavenSpacing.sm),
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(
              horizontal: HavenSpacing.md,
              vertical: HavenSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: EdgeInsets.only(
                    left: i > 0 ? 4.0 : 0,
                  ),
                  child: _TypingDot(delayMs: i * 200),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HavenSpacing.sm),
      color: HavenColors.moodBad.withAlpha(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: HavenTypography.caption.copyWith(
              color: HavenColors.moodBad,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: HavenSpacing.md,
        right: HavenSpacing.xs,
        bottom: MediaQuery.of(context).viewInsets.bottom + HavenSpacing.sm,
        top: HavenSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: HavenColors.textSecondary.withAlpha(20),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: HavenTypography.body.copyWith(
                color: HavenColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: '说说你想说的...',
                hintStyle: HavenTypography.body.copyWith(
                  color: HavenColors.textSecondary.withAlpha(120),
                ),
                filled: true,
                fillColor: HavenColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: HavenSpacing.md,
                  vertical: HavenSpacing.sm,
                ),
              ),
            ),
          ),
          const SizedBox(width: HavenSpacing.xs),
          // Send button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: HavenColors.primary.withAlpha(200),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 18,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single animated typing dot.
class _TypingDot extends StatefulWidget {
  final int delayMs;

  const _TypingDot({required this.delayMs});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 7 * _animation.value,
          height: 7 * _animation.value,
          decoration: BoxDecoration(
            color: HavenColors.textSecondary
                .withAlpha(60 + (_animation.value * 180).toInt()),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
