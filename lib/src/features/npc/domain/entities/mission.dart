class Mission {
  final String id;
  final String npcId;
  final String description;
  final bool isCompleted;

  const Mission({
    required this.id,
    required this.npcId,
    required this.description,
    this.isCompleted = false,
  });

  Mission copyWith({
    String? id,
    String? npcId,
    String? description,
    bool? isCompleted,
  }) =>
      Mission(
        id: id ?? this.id,
        npcId: npcId ?? this.npcId,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}
