import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// A single chat bubble.
///
/// User bubbles: right-aligned, primary color
/// Assistant bubbles: left-aligned, white card
///
/// Design follows Haven principles: calm, gentle, readable.
class ChatBubble extends StatelessWidget {
  final ChatModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: HavenSpacing.xs,
        horizontal: HavenSpacing.md,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(),
          if (!isUser) const SizedBox(width: HavenSpacing.sm),
          Flexible(
            child: isUser ? _buildUserBubble() : _buildAssistantBubble(),
          ),
          if (isUser) const SizedBox(width: HavenSpacing.sm),
          if (isUser) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildUserBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(
        horizontal: HavenSpacing.md,
        vertical: HavenSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: HavenColors.primary.withAlpha(220),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Text(
        message.content,
        style: HavenTypography.body.copyWith(
          color: Colors.white,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildAssistantBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(
        horizontal: HavenSpacing.md,
        vertical: HavenSpacing.sm + 2,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.content,
            style: HavenTypography.body.copyWith(
              color: HavenColors.textPrimary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          if (message.isStreaming) ...[
            const SizedBox(height: HavenSpacing.xs),
            _buildTypingIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(0),
        const SizedBox(width: 4),
        _dot(300),
        const SizedBox(width: 4),
        _dot(600),
      ],
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: 6 * value,
          height: 6 * value,
          decoration: BoxDecoration(
            color: HavenColors.textSecondary.withAlpha(100 + (value * 100).toInt()),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    final isUser = message.isUser;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? HavenColors.primary.withAlpha(30)
            : HavenColors.secondary.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        isUser ? '我' : '伴',
        style: HavenTypography.caption.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isUser ? HavenColors.primary : HavenColors.secondary,
        ),
      ),
    );
  }
}
