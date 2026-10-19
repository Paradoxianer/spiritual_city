import 'dart:math' as math;

import 'npc_model.dart';

/// Roles in the church (#181, progression_and_unlocks.md §4): "Er hat
/// gegeben … zur Zurüstung der Heiligen zum Werk des Dienstes" (Eph 4:11–12);
/// many members, one body (1 Cor 12).
enum ChurchRole {
  /// 🙏 Fürbeter – faith for the pastor every day.
  intercessor('🙏'),

  /// 📖 Hauskreisleiter – insight every day.
  smallGroupLeader('📖'),

  /// 🤝 Helfer – supplies every day.
  helper('🤝'),

  /// 🩹 Verwundeter Heiler – helps people with the same wound in the life
  /// talk (2 Cor 1:4).
  woundedHealer('🩹');

  final String emoji;
  const ChurchRole(this.emoji);

  ChurchRole get next => ChurchRole.values[(index + 1) % ChurchRole.values.length];
}

/// One church member – kept centrally so members count even when their
/// part of the city is not loaded (#170).
class ChurchMember {
  final String npcId;
  final String name;
  ChurchRole role;

  /// Ids of life events this person has worked through (their "healed
  /// wounds") – a 🩹 healer can help others with the same ones.
  final Set<String> healedEventIds;

  /// Glyphs of those events, for the overview.
  final Map<String, String> healedGlyphs;

  /// Day on which a 🩹 healer last helped (one help per day).
  int lastHelpDay;

  ChurchMember({
    required this.npcId,
    required this.name,
    required this.role,
    Set<String>? healedEventIds,
    Map<String, String>? healedGlyphs,
    this.lastHelpDay = 0,
  })  : healedEventIds = healedEventIds ?? {},
        healedGlyphs = healedGlyphs ?? {};

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role.name,
        'healed': healedGlyphs,
        if (lastHelpDay > 0) 'help': lastHelpDay,
      };

  static ChurchMember fromJson(String id, Map raw) {
    final healed = <String, String>{
      for (final e in ((raw['healed'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}',
    };
    return ChurchMember(
      npcId: id,
      name: '${raw['name'] ?? ''}',
      role: ChurchRole.values.firstWhere((r) => r.name == raw['role'],
          orElse: () => ChurchRole.intercessor),
      healedEventIds: healed.keys.toSet(),
      healedGlyphs: healed,
      lastHelpDay: (raw['help'] as num?)?.toInt() ?? 0,
    );
  }
}

/// What the church brought in at the end of a day.
class ChurchYield {
  final double faith;
  final double insight;
  final double materials;
  const ChurchYield({this.faith = 0, this.insight = 0, this.materials = 0});

  bool get isEmpty => faith <= 0 && insight <= 0 && materials <= 0;

  /// `⛪ +12🙏 +0.6📖 +9📦`
  String get label => [
        '⛪',
        if (faith > 0) '+${faith.round()}🙏',
        if (insight > 0) '+${insight.toStringAsFixed(1)}📖',
        if (materials > 0) '+${materials.round()}📦',
      ].join(' ');
}

/// The pastor's church: members, roles and their daily yield.
class Church {
  final Map<String, ChurchMember> members = {};

  // Startwerte (zentral hier, GameBalance #83):
  static const double faithPerIntercessor = 6.0;
  static const double insightPerLeader = 0.3;
  static const double materialsPerHelper = 5.0;

  /// Flat with diminishing returns: n members of a role give n^0.8 shares,
  /// so a big church helps a lot but never explodes.
  static double _shares(int n) => n <= 0 ? 0 : math.pow(n, 0.8).toDouble();

  int count(ChurchRole role) => members.values.where((m) => m.role == role).length;

  ChurchYield dailyYield() => ChurchYield(
        faith: _shares(count(ChurchRole.intercessor)) * faithPerIntercessor,
        insight: _shares(count(ChurchRole.smallGroupLeader)) * insightPerLeader,
        materials: _shares(count(ChurchRole.helper)) * materialsPerHelper,
      );

  /// Role for a new member: someone who has worked through a wound becomes a
  /// 🩹 healer; otherwise it follows the person's need.
  static ChurchRole initialRole(NPCModel npc) {
    if (npc.backstory.resolvedChallenges.isNotEmpty) return ChurchRole.woundedHealer;
    return switch (npc.need) {
      NpcNeed.seeking => ChurchRole.smallGroupLeader,
      NpcNeed.needy => ChurchRole.helper,
      NpcNeed.lonely || NpcNeed.doubting => ChurchRole.intercessor,
    };
  }

  /// Adds [npc] (just converted) as a member; returns it.
  ChurchMember join(NPCModel npc) => members.putIfAbsent(
        npc.id,
        () => ChurchMember(
          npcId: npc.id,
          name: npc.name,
          role: initialRole(npc),
        ),
      )..healedFrom(npc);

  /// Records a wound [npc] has worked through (if they are a member).
  void recordHealed(NPCModel npc) => members[npc.id]?.healedFrom(npc);

  /// A 🩹 healer who has worked through [eventId] and has not helped
  /// today, other than [exceptNpcId].
  ChurchMember? healerFor(String eventId, int today, {String? exceptNpcId}) {
    for (final m in members.values) {
      if (m.role != ChurchRole.woundedHealer) continue;
      if (m.npcId == exceptNpcId || m.lastHelpDay >= today) continue;
      if (m.healedEventIds.contains(eventId)) return m;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {for (final m in members.values) m.npcId: m.toJson()};

  void loadFromJson(Object? raw) {
    members.clear();
    if (raw is! Map) return;
    for (final e in raw.entries) {
      if (e.value is Map) members['${e.key}'] = ChurchMember.fromJson('${e.key}', e.value as Map);
    }
  }
}

extension on ChurchMember {
  void healedFrom(NPCModel npc) {
    for (final o in npc.backstory.resolvedChallenges) {
      healedEventIds.add(o.event.id);
      healedGlyphs[o.event.id] = o.event.glyph;
    }
  }
}
