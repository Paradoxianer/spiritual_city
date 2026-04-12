/// Emoji-based NPC reaction after a conversation session.
enum ReactionType {
  happy,      // 😊
  grateful,   // 🙏
  curious,    // 🤔
  suspicious, // 😕
  sad,        // 😢
  grumpy,     // 😠
  confused,   // 😵
  blessed,    // 🕊️
}

class NPCReaction {
  final ReactionType type;
  final String emoji;

  NPCReaction._(this.type, this.emoji);

  /// Selects a reaction based on [faithLevel] and whether the player gave a
  /// gift this session.
  factory NPCReaction.fromFaithLevel(double faithLevel, {bool gotGift = false}) {
    if (faithLevel > 50) return NPCReaction._(ReactionType.blessed, '🕊️');
    if (faithLevel > 20) return NPCReaction._(ReactionType.grateful, '🙏');
    if (faithLevel > 0) {
      return gotGift
          ? NPCReaction._(ReactionType.grateful, '🙏')
          : NPCReaction._(ReactionType.curious, '🤔');
    }
    if (faithLevel < -50) return NPCReaction._(ReactionType.grumpy, '😠');
    if (faithLevel < -20) {
      return gotGift
          ? NPCReaction._(ReactionType.suspicious, '😕')
          : NPCReaction._(ReactionType.sad, '😢');
    }
    return NPCReaction._(ReactionType.confused, '😵');
  }
}
