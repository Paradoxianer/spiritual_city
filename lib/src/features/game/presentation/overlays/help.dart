part of '../game_screen.dart';

/// ❓ Help (pause menu, F1 / ?, tapping the 🎓 line): the one screen with
/// real sentences (playtest 2026-10-20: "Aufgabe 📢 bekommen, finde nicht,
/// wie ich sie ausführe"). Four tabs:
///  * 🎓 my tasks – the running tutorial step and lesson and *how* to do it,
///    what can be learned now and where, where learned abilities are used;
///  * 🧭 first steps – the tutorial steps to reread, and what comes after;
///  * 📖 glossary – every emoji, searchable, generated from the registries;
///  * ⌨️ keys.
class HelpOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const HelpOverlay({super.key, required this.game});

  @override
  State<HelpOverlay> createState() => _HelpOverlayState();
}

class _HelpOverlayState extends State<HelpOverlay> {
  late int _tab = widget.game.helpTab;
  String _query = '';

  static const _tabs = [('🎓', 'tasks'), ('🧭', 'steps'), ('📖', 'glossary'), ('⌨️', 'keys')];

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          color: Colors.black.withValues(alpha: 0.92),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                      child: Row(
                        children: [
                          const Text('❓', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (var i = 0; i < _tabs.length; i++) _tabButton(i),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            tooltip: 'F1 / ?',
                            onPressed: game.closeHelp,
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    Expanded(
                      child: switch (_tab) {
                        0 => _HelpTasks(game: game),
                        1 => _HelpSteps(game: game),
                        2 => _HelpGlossary(
                            game: game,
                            query: _query,
                            onQuery: (q) => setState(() => _query = q),
                          ),
                        _ => const _HelpKeys(),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(int i) {
    final (emoji, key) = _tabs[i];
    final selected = _tab == i;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _tab = i),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0x55FFD54F) : Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                HelpContent.title(key),
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Building blocks ────────────────────────────────────────────────────────────

/// A row of the help: big emoji on the left, sentence and an optional grey
/// line (costs, mentors …) on the right.
class _HelpRow extends StatelessWidget {
  final String emoji;
  final String text;
  final String? sub;
  final Widget? trailing;
  const _HelpRow({required this.emoji, required this.text, this.sub, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35)),
                if (sub != null && sub!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(sub!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _HelpHeading extends StatelessWidget {
  final String text;
  const _HelpHeading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      );
}

/// A highlighted card (the running lesson / tutorial step).
class _HelpCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  const _HelpCard({required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 6, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: const Border(left: BorderSide(color: Color(0xFFFFD54F), width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}

String _buildingNames(Iterable<BuildingType> types) =>
    types.map((t) => '${BuildingComponent.buildingEmoji(t)} ${HelpContent.buildings[t]!.text}').join(', ');

/// Where a learned [skill] is used: the buildings that offer its action, or
/// the invisible world for combat skills.
String _whereUsed(Skill skill) {
  final types = [
    for (final t in BuildingType.values)
      if (BuildingActions.forType(t).any((a) => a.needsSkill == skill)) t,
  ];
  if (types.isNotEmpty) return '📍 ${_buildingNames(types)}';
  if (skill == Skill.pastoralCare) return '📍 👤 📜';
  return '📍 🌐 ${HelpContent.title('invisible')}';
}

// ── 🎓 My tasks ────────────────────────────────────────────────────────────────

class _HelpTasks extends StatelessWidget {
  final SpiritWorldGame game;
  const _HelpTasks({required this.game});

  @override
  Widget build(BuildContext context) {
    final p = game.progress;
    final awakenings = p.awakenedQuarters.length;
    final step = game.tutorialService.currentStep;
    final active = p.lesson.lesson;
    final open = [
      for (final l in Lessons.all)
        if (l.isOpen(p.skills, awakenings) && l != active) l,
    ];
    final learned = [
      for (final s in Skill.values)
        if (p.skills.has(s)) s
    ];

    return ValueListenableBuilder<String?>(
      valueListenable: game.trackedMission,
      builder: (context, tracked, _) {
        Widget track(Lesson l) {
          final key = GameMissionTracking.lessonKey(l.skill);
          return ActionButton(
            emoji: tracked == key ? '📍✅' : '📍',
            highlighted: tracked == key,
            onTap: () => game.toggleTrackedMission(key),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (step != null && step != TutorialStep.completed)
              _HelpCard(
                emoji: step.emoji,
                title: '${HelpContent.title('tutorial')}: ${AppStrings.get('tutorial.${step.name}.goal')}',
                body: AppStrings.get('tutorial.${step.name}.detail'),
              ),
            if (active != null)
              _HelpCard(
                emoji: '🎓${active.skill.emoji}',
                title: '${active.progressLabel(p.lesson.progress)}  ·  ${HelpContent.skills[active.skill]!.text}',
                body: HelpContent.taskHowTo[active.task]!.text,
              )
            else if (open.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child:
                    Text(HelpContent.title('noLesson'), style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
              ),
            if (open.isNotEmpty) ...[
              if (active != null) _HelpHeading(HelpContent.title('lessons')),
              for (final l in open)
                _HelpRow(
                  emoji: '🎓${l.skill.emoji}',
                  text: HelpContent.skills[l.skill]!.text,
                  sub: '${HelpContent.title('mentors')}: ${_buildingNames(l.mentorAt)}\n'
                      '${l.task.emoji} ×${l.count} – ${HelpContent.taskHowTo[l.task]!.text}',
                  trailing: track(l),
                ),
            ],
            if (learned.isNotEmpty) ...[
              _HelpHeading(HelpContent.title('learned')),
              for (final s in learned)
                _HelpRow(
                  emoji: s.emoji,
                  text: HelpContent.skills[s]!.text,
                  sub: _whereUsed(s),
                ),
            ],
            const _HelpHeading('🏘️🔥'),
            _HelpRow(
              emoji: '🔥 $awakenings',
              text: HelpContent.title('awakened'),
              sub: HelpContent.nextSteps[2].$3.text,
            ),
          ],
        );
      },
    );
  }
}

// ── 🧭 First steps ─────────────────────────────────────────────────────────────

class _HelpSteps extends StatelessWidget {
  final SpiritWorldGame game;
  const _HelpSteps({required this.game});

  @override
  Widget build(BuildContext context) {
    final current = game.tutorialService.currentStep;
    final steps = [
      for (final s in TutorialStep.values)
        if (s != TutorialStep.completed)
          (
            s.emoji,
            AppStrings.get('tutorial.${s.name}.goal'),
            AppStrings.get('tutorial.${s.name}.detail'),
            s == current
          ),
      for (final (emoji, title, body) in HelpContent.nextSteps) (emoji, title.text, body.text, false),
    ];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: steps.length,
      itemBuilder: (context, i) {
        final (emoji, title, body, isCurrent) = steps[i];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCurrent ? const Color(0x33FFD54F) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text('${i + 1}',
                    style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 48, child: Text(emoji, style: const TextStyle(fontSize: 20))),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 📖 Glossary ────────────────────────────────────────────────────────────────

typedef _GlossaryEntry = ({String emoji, String text, String? sub});

class _HelpGlossary extends StatelessWidget {
  final SpiritWorldGame game;
  final String query;
  final ValueChanged<String> onQuery;
  const _HelpGlossary({required this.game, required this.query, required this.onQuery});

  /// All sections, generated from the registries so new actions and lessons
  /// show up by themselves.
  List<(String, List<_GlossaryEntry>)> _sections() {
    final d = game.difficulty;
    _GlossaryEntry action(GameAction a) => (
          emoji: a.emoji,
          text: HelpContent.actions[a.id]!.text,
          sub: [
            a.hint(d),
            if (a.needsSkill != null) '🎓${a.needsSkill!.emoji}',
          ].join('   '),
        );

    // Building types with the same actions (shop, supermarket …) share a block.
    final groups = <String, List<BuildingType>>{};
    for (final t in BuildingType.values) {
      groups.putIfAbsent(BuildingActions.forType(t).map((a) => a.type).join(','), () => []).add(t);
    }

    return [
      (
        HelpContent.title('resources'),
        [
          for (final r in Resource.values) (emoji: r.emoji, text: HelpContent.resources[r]!.text, sub: null),
        ],
      ),
      (
        HelpContent.title('symbols'),
        [for (final (e, t) in HelpContent.symbols) (emoji: e, text: t.text, sub: null)],
      ),
      (
        '👤 ${HelpContent.title('people')}',
        [
          for (final a in [...NpcActions.chat, NpcActions.lifeTalk]) action(a)
        ],
      ),
      for (final types in groups.values)
        (
          types.map((t) => '${BuildingComponent.buildingEmoji(t)} ${HelpContent.buildings[t]!.text}').join(' · '),
          [for (final a in BuildingActions.forType(types.first)) action(a)],
        ),
      (
        '🌐 ${HelpContent.title('spirit')}',
        [
          for (final m in PrayerMode.values) (emoji: m.icon, text: HelpContent.prayerModes[m]!.text, sub: null),
          for (final k in DaemonKind.values)
            (emoji: k.glyph, text: HelpContent.daemons[k]!.text, sub: '💥 ${k.weakness.icon}'),
        ],
      ),
      (
        '🎓 ${HelpContent.title('lessons')}',
        [
          for (final l in Lessons.all)
            (
              emoji: l.skill.emoji,
              text: HelpContent.skills[l.skill]!.text,
              sub: [
                '${HelpContent.title('mentors')}: ${_buildingNames(l.mentorAt)}',
                '${l.task.emoji} ×${l.count}: ${HelpContent.taskHowTo[l.task]!.text}',
                if (l.requires.isNotEmpty || l.minAwakenings > 0)
                  '🔒 ${[
                    for (final r in l.requires) r.emoji,
                    if (l.minAwakenings > 0) '🏰🔥×${l.minAwakenings}'
                  ].join(' ')}',
              ].join('  ·  '),
            ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    bool matches(_GlossaryEntry e) =>
        q.isEmpty ||
        e.emoji.toLowerCase().contains(q) ||
        e.text.toLowerCase().contains(q) ||
        (e.sub?.toLowerCase().contains(q) ?? false);

    final children = <Widget>[];
    for (final (title, entries) in _sections()) {
      final hit = q.isNotEmpty && title.toLowerCase().contains(q);
      final shown = hit ? entries : entries.where(matches).toList();
      if (shown.isEmpty) continue;
      children.add(_HelpHeading(title));
      for (final e in shown) {
        children.add(_HelpRow(emoji: e.emoji, text: e.text, sub: e.sub));
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: TextField(
            onChanged: onQuery,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              hintText: HelpContent.title('search'),
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: children.isEmpty
              ? const Center(child: Text('🔍🤷', style: TextStyle(fontSize: 32)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: children,
                ),
        ),
      ],
    );
  }
}

// ── ⌨️ Keys ────────────────────────────────────────────────────────────────────

class _HelpKeys extends StatelessWidget {
  const _HelpKeys();

  @override
  Widget build(BuildContext context) {
    final categories = <String, List<KeymapEntry>>{};
    for (final entry in GameKeymap.entries) {
      categories.putIfAbsent(entry.category, () => []).add(entry);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final cat in categories.values) ...[
          _HelpHeading(cat.first.localizedCategory),
          ...cat.map((e) => _KeyRow(entry: e)),
        ],
      ],
    );
  }
}
