import 'package:flutter/material.dart';
import '../controllers/medbot_controller.dart';
import '../models/chat_message_model.dart';
import '../theme/app_theme.dart';

// ─── MedBot View ──────────────────────────────────────────────
// Chat UI screen — no Provider, uses MedBotController directly
class MedBotView extends StatefulWidget {
  const MedBotView({super.key});

  @override
  State<MedBotView> createState() => _MedBotViewState();
}

class _MedBotViewState extends State<MedBotView> {
  // Controller created directly — no Provider needed
  final MedBotController _controller = MedBotController();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Quick suggestion chips
  final List<String> _suggestions = [
    'What if I missed a dose?',
    'What are common side effects?',
    'Is it safe to skip a day?',
    'Can I take medicine on empty stomach?',
  ];

  @override
  void initState() {
    super.initState();
    // Listen to controller changes to rebuild UI
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Rebuild when controller notifies
  void _onControllerUpdate() {
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  // Scroll to bottom after new message
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Send message
  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    await _controller.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MedBot',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  )),
              Text('Your medicine assistant',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textLight)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined,
                color: AppTheme.textLight),
            onPressed: _controller.clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(children: [

        // ── Suggestion chips (only shown at start) ──────
        if (_controller.messages.length <= 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick questions:',
                    style: TextStyle(
                      fontSize: 12, color: AppTheme.textLight,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: _suggestions.map<Widget>((s) =>
                      GestureDetector(
                        onTap: () => _send(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primary.withOpacity(0.2)),
                          ),
                          child: Text(s,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              )),
                        ),
                      ),
                  ).toList(),
                ),
              ],
            ),
          ),

        // ── Chat messages list ───────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: _controller.messages.length +
                (_controller.isLoading ? 1 : 0),
            itemBuilder: (_, i) {
              // Loading bubble
              if (i == _controller.messages.length &&
                  _controller.isLoading) {
                return _buildLoadingBubble();
              }
              return _buildMessageBubble(_controller.messages[i]);
            },
          ),
        ),

        // ── Input bar ────────────────────────────────────
        _buildInputBar(),
      ]),
    );
  }

  // ── MESSAGE BUBBLE ────────────────────────────────────────
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  size: 16, color: AppTheme.primary),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFE8EEF4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : AppTheme.textDark,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  size: 16, color: AppTheme.primary),
            ),
          ],
        ],
      ),
    );
  }

  // ── LOADING BUBBLE ────────────────────────────────────────
  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: const Color(0xFFE8EEF4)),
            ),
            child: const _TypingIndicator(),
          ),
        ],
      ),
    );
  }

  // ── INPUT BAR ─────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _textController,
            enabled: !_controller.isLoading,
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: _send,
            decoration: InputDecoration(
              hintText: 'Ask MedBot a question...',
              hintStyle: const TextStyle(
                  color: AppTheme.textLight, fontSize: 14),
              filled: true,
              fillColor: AppTheme.background,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _controller.isLoading
              ? null
              : () => _send(_textController.text),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _controller.isLoading
                  ? AppTheme.primary.withOpacity(0.5)
                  : AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

// ─── Typing Indicator ─────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.33;
          final v = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final size = 6.0 + (v < 0.5 ? v * 2 : (1 - v) * 2) * 4;
          return Container(
            width: size, height: size,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.4 + v * 0.6),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}