/// Abilities the pastor learns from mentors through learning missions
/// (docs/game_design/release_roadmap.md §3.9, "Jüngerschaft").
///
/// New games start without them; saves from before learning missions keep
/// what they could already do (decision 2026-10-17: new games learn, old
/// games keep).
enum Skill {
  /// 🫂 Seelsorge – unlocks the 📜 life-story talks (2 Cor 1:4).
  pastoralCare('🫂'),

  /// ⚔️ Geistlicher Kampf – unlocks 🫸 Rebuke (Eph 6:10–18). Slow and
  /// Drain are learned one by one after it (playtest 2026-10-18).
  spiritualWarfare('⚔️'),

  /// ⏳ Binden – unlocks Slow (Mt 18:18).
  binding('⏳'),

  /// 🪫 Entwaffnen – unlocks Drain (Col 2:15).
  disarming('🪫'),

  /// 👁️ Unterscheidung der Geister – daemon kinds become visible
  /// (1 Cor 12:10).
  discernment('👁️'),

  /// 🙏 Fürbitte – intercession for a house (1 Tim 2:1).
  intercession('🙏'),

  /// 🍞 Fasten – fasting before prayer (Matt 6:16–18, Mark 9:29).
  fasting('🍞'),

  /// 📢 Predigen – preaching to a crowd (Rom 10:14).
  preaching('📢'),

  // Mastery per prayer mode: lifts the upgrade cap of that mode (level 2 →
  // 5 → 10), which also opens its two special abilities.
  liberationMastery1('🕊️⭐'),
  liberationMastery2('🕊️⭐⭐'),
  rebukeMastery1('🫸⭐'),
  rebukeMastery2('🫸⭐⭐'),
  slowMastery1('⏳⭐'),
  slowMastery2('⏳⭐⭐'),
  drainMastery1('🪫⭐'),
  drainMastery2('🪫⭐⭐');

  final String emoji;
  const Skill(this.emoji);
}

/// The set of learned [Skill]s, persisted with the player progress.
class LearnedSkills {
  final Set<Skill> _learned;

  LearnedSkills([Set<Skill>? learned]) : _learned = {...?learned};

  /// What a save from before learning missions already could do: life
  /// talks and all combat modes (plus discernment, so the new daemon kinds
  /// are visible). New abilities still have to be learned.
  static const Set<Skill> legacy = {
    Skill.pastoralCare,
    Skill.spiritualWarfare,
    Skill.binding,
    Skill.disarming,
    Skill.discernment,
  };

  bool has(Skill s) => _learned.contains(s);

  /// Returns true when [s] was newly learned.
  bool learn(Skill s) => _learned.add(s);

  Iterable<Skill> get all => _learned;

  List<String> toJson() => [for (final s in _learned) s.name];

  /// `null` (field missing in an old save) means [legacy].
  void loadFromJson(Object? raw) {
    _learned.clear();
    if (raw is! List) {
      _learned.addAll(legacy);
      return;
    }
    for (final name in raw) {
      for (final s in Skill.values) {
        if (s.name == name) _learned.add(s);
      }
    }
  }
}
