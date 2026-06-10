// ─── Model ────────────────────────────────────────────────────
// Represents a single message in the chat
class ChatMessage {
  final String text;
  final bool isUser;       // true = user, false = MedBot
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}