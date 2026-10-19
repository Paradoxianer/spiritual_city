import '../../../menu/domain/models/difficulty.dart';
import '../models/building_model.dart';
import '../models/cell_object.dart';
import '../services/building_interaction_service.dart';
import 'game_action.dart';
import 'practice.dart';
import 'resource.dart';

/// All actions available inside buildings, per building type, in keyboard
/// order. Costs here are the single source of truth: the UI shows and checks
/// them, and `SpiritWorldGame.handleBuildingAction` refuses before the
/// service runs. A test keeps them in line with the deltas of
/// [BuildingInteractionService].
abstract final class BuildingActions {
  /// Lock emoji while the building has been visited [n] times or fewer:
  /// `🔒3` = three more visits needed.
  static String? _needsVisits(BuildingModel b, int n) =>
      b.interactionCount <= n ? '🔒${n + 1 - b.interactionCount}' : null;

  static ResourceCost Function(Difficulty) _c(Map<Resource, double> m) =>
      (_) => ResourceCost(m);

  // ── Pastor house ────────────────────────────────────────────────────────

  static final readBible = GameAction<BuildingModel>(
    id: ActionId.readBible,
    type: 'readBible',
    emoji: '📖',
    effect: '🙏+${BuildingInteractionService.pastorHouseReadBibleFaith.round()}',
    baseSeconds: BuildingInteractionService.pastorHouseReadBibleSeconds,
    discipline: Discipline.bible,
  );
  static const eat = GameAction<BuildingModel>(
    id: ActionId.eat,
    type: 'eat',
    emoji: '🍽️',
    effect: '🍞+50',
    baseSeconds: BuildingInteractionService.pastorHouseEatSeconds,
  );
  static const sleep = GameAction<BuildingModel>(
    id: ActionId.sleep,
    type: 'sleep',
    emoji: '😴',
    effect: '❤️+50',
    baseSeconds: BuildingInteractionService.pastorHouseSleepSeconds,
  );
  static final homePray = GameAction<BuildingModel>(
    id: ActionId.homePray,
    type: 'pray',
    emoji: '🙏',
    effect: '🙏+${BuildingInteractionService.pastorHousePrayFaith.round()}🌍',
    baseSeconds: BuildingInteractionService.pastorHousePraySeconds,
    discipline: Discipline.prayer,
  );
  static const missions = GameAction<BuildingModel>(
    id: ActionId.missions,
    type: 'missions',
    emoji: '📋',
    effect: '📜',
  );

  // ── Homes ───────────────────────────────────────────────────────────────

  static final practicalHelp = GameAction<BuildingModel>(
    id: ActionId.practicalHelp,
    type: 'practicalHelp',
    emoji: '🛠️',
    effect: '✝️+5',
    cost: _c({Resource.materials: 10}),
    discipline: Discipline.service,
  );
  static final housePray = GameAction<BuildingModel>(
    id: ActionId.housePray,
    type: 'pray',
    emoji: '🙏',
    effect: '🕊️?',
    cost: _c({Resource.faith: 10}),
    discipline: Discipline.prayer,
  );
  static final houseVisit = GameAction<BuildingModel>(
    id: ActionId.houseVisit,
    type: 'houseVisit',
    emoji: '☕',
    effect: '❤️🍞',
    baseSeconds: BuildingInteractionService.houseVisitSeconds,
    discipline: Discipline.conversation,
    lockedBy: (b) => _needsVisits(b, 5),
  );
  static final discipleshipGroup = GameAction<BuildingModel>(
    id: ActionId.discipleshipGroup,
    type: 'discipleshipGroup',
    emoji: '📖👥',
    effect: '📖+0.5',
    cost: _c({Resource.faith: 50}),
    discipline: Discipline.bible,
    lockedBy: (b) =>
        _needsVisits(b, 20) ??
        (b.residents.any((n) => n.isChristian) ? null : '🔒✝️'),
  );
  static final blessHousehold = GameAction<BuildingModel>(
    id: ActionId.blessHousehold,
    type: 'blessHousehold',
    emoji: '🏢',
    effect: '✝️👥',
    cost: _c({Resource.faith: 10}),
    discipline: Discipline.prayer,
  );

  // ── Church ──────────────────────────────────────────────────────────────

  static final sundayService = GameAction<BuildingModel>(
    id: ActionId.sundayService,
    type: 'sundayService',
    emoji: '⛪',
    effect: '🙏+${BuildingInteractionService.sundayServiceFaith.round()}🔥',
    cost: _c({
      Resource.materials: 50,
      Resource.health: BuildingInteractionService.sundayServiceHealthCost,
    }),
    baseSeconds: BuildingInteractionService.sundayServiceSeconds,
    discipline: Discipline.worship,
  );
  static final worship = GameAction<BuildingModel>(
    id: ActionId.worship,
    type: 'worship',
    emoji: '🤲',
    effect: '🙏+${(BuildingInteractionService.worshipSeconds * BuildingInteractionService.worshipFaithPerSecond).round()}',
    baseSeconds: BuildingInteractionService.worshipSeconds,
    discipline: Discipline.worship,
  );

  // ── Hospital ────────────────────────────────────────────────────────────

  static final medicalHelp = GameAction<BuildingModel>(
    id: ActionId.medicalHelp,
    type: 'medicalHelp',
    emoji: '🏥',
    effect: '❤️🍞💯',
    cost: _c({Resource.materials: 15}),
  );
  static final counseling = GameAction<BuildingModel>(
    id: ActionId.counseling,
    type: 'counseling',
    emoji: '👂',
    effect: '✝️👥',
    baseSeconds: BuildingInteractionService.counselingSeconds,
    discipline: Discipline.counsel,
    lockedBy: (b) => _needsVisits(b, 3),
  );
  static final chapelService = GameAction<BuildingModel>(
    id: ActionId.chapelService,
    type: 'chapelService',
    emoji: '⛪',
    effect: '✝️+15👥',
    cost: _c({Resource.faith: 30}),
    discipline: Discipline.worship,
    lockedBy: (b) => _needsVisits(b, 10),
  );

  // ── School / university ─────────────────────────────────────────────────

  static final letterToManagement = GameAction<BuildingModel>(
    id: ActionId.letterToManagement,
    type: 'letterToManagement',
    emoji: '✉️',
    effect: '✝️+2',
    cost: _c({Resource.materials: 5}),
  );
  static final talkDirector = GameAction<BuildingModel>(
    id: ActionId.talkDirector,
    type: 'talkDirector',
    emoji: '🏫',
    effect: '✝️+5🎤',
    baseSeconds: BuildingInteractionService.talkDirectorSeconds,
    discipline: Discipline.conversation,
    lockedBy: (b) => _needsVisits(b, 5),
  );
  static final valueLecture = GameAction<BuildingModel>(
    id: ActionId.valueLecture,
    type: 'valueLecture',
    emoji: '🎤',
    effect: '✝️👥',
    baseSeconds: BuildingInteractionService.valueLectureSeconds,
    discipline: Discipline.bible,
    lockedBy: (b) =>
        _needsVisits(b, 15) ?? (b.isLecturePrepared ? null : '🔒🏫'),
  );
  static final prayerCircle = GameAction<BuildingModel>(
    id: ActionId.prayerCircle,
    type: 'prayerCircle',
    emoji: '⭕',
    effect: '📖+0.5',
    cost: _c({Resource.faith: 60}),
    discipline: Discipline.prayer,
    lockedBy: (b) => _needsVisits(b, 30),
  );

  // ── Cemetery ────────────────────────────────────────────────────────────

  static const funeral = GameAction<BuildingModel>(
    id: ActionId.funeral,
    type: 'funeral',
    emoji: '⚰️',
    effect: '✝️👥',
    baseSeconds: BuildingInteractionService.funeralSeconds,
    discipline: Discipline.counsel,
  );
  static final comfort = GameAction<BuildingModel>(
    id: ActionId.comfort,
    type: 'comfort',
    emoji: '🤝',
    effect: '✝️!',
    cost: _c({Resource.health: 75, Resource.hunger: 75}),
    discipline: Discipline.counsel,
    lockedBy: (b) => b.hasFuneralCompleted ? null : '🔒⚰️',
  );

  // ── Police / city hall / station / stadium ──────────────────────────────

  static final blessPolice = GameAction<BuildingModel>(
    id: ActionId.blessPolice,
    type: 'blessPolice',
    emoji: '👮',
    effect: '🛡️',
    cost: _c({Resource.faith: 15}),
    discipline: Discipline.prayer,
  );
  static const mayorAudience = GameAction<BuildingModel>(
    id: ActionId.mayorAudience,
    type: 'mayorAudience',
    emoji: '🏛️',
    effect: '✝️+3',
    baseSeconds: BuildingInteractionService.mayorAudienceSeconds,
    discipline: Discipline.conversation,
  );
  static final prayForPoliticians = GameAction<BuildingModel>(
    id: ActionId.prayForPoliticians,
    type: 'prayForPoliticians',
    emoji: '🙏🏛️',
    effect: '🌍',
    cost: _c({Resource.faith: 100, Resource.health: 50, Resource.hunger: 50}),
    baseSeconds: BuildingInteractionService.prayForPoliticiansSeconds,
    discipline: Discipline.prayer,
    lockedBy: (b) => _needsVisits(b, 20),
  );
  static final travel = GameAction<BuildingModel>(
    id: ActionId.travel,
    type: 'travel',
    emoji: '🚂',
    effect: '🗺️',
    cost: _c({Resource.materials: 10}),
  );
  static final majorEvent = GameAction<BuildingModel>(
    id: ActionId.majorEvent,
    type: 'majorEvent',
    emoji: '🏟️',
    effect: '📖+0.5',
    cost: _c({Resource.faith: 100, Resource.materials: 100}),
    discipline: Discipline.worship,
    lockedBy: (b) => _needsVisits(b, 50),
  );

  // ── Commercial ──────────────────────────────────────────────────────────

  static const talkBoss = GameAction<BuildingModel>(
    id: ActionId.talkBoss,
    type: 'talkBoss',
    emoji: '💼',
    effect: '✝️+3',
    baseSeconds: BuildingInteractionService.talkBossSeconds,
    discipline: Discipline.conversation,
  );
  static final shopping = GameAction<BuildingModel>(
    id: ActionId.shopping,
    type: 'shopping',
    emoji: '🛒',
    effect: '🍞❤️',
    cost: _c({Resource.materials: 5}),
  );
  static final bless = GameAction<BuildingModel>(
    id: ActionId.bless,
    type: 'bless',
    emoji: '🕊️',
    effect: '✝️+2',
    cost: _c({Resource.faith: 15}),
    discipline: Discipline.prayer,
  );
  static final requestDonation = GameAction<BuildingModel>(
    id: ActionId.requestDonation,
    type: 'requestDonation',
    emoji: '🤲',
    effect: '📦?',
    cost: _c({Resource.health: 10, Resource.hunger: 10}),
    lockedBy: (b) => _needsVisits(b, 2),
  );

  // ── Generic ─────────────────────────────────────────────────────────────

  static const genericPray = GameAction<BuildingModel>(
    id: ActionId.genericPray,
    type: 'pray',
    emoji: '🙏',
    effect: '🙏✝️',
    discipline: Discipline.prayer,
  );
  static final witness = GameAction<BuildingModel>(
    id: ActionId.witness,
    type: 'witness',
    emoji: '💬',
    effect: '✝️',
    cost: _c({Resource.materials: 3}),
    discipline: Discipline.conversation,
  );
  static final distribute = GameAction<BuildingModel>(
    id: ActionId.distribute,
    type: 'distribute',
    emoji: '📦',
    effect: '✝️',
    cost: _c({Resource.materials: 8}),
    discipline: Discipline.service,
  );

  /// Actions of a building type, in keyboard order (key 1 = first).
  static List<GameAction<BuildingModel>> forType(BuildingType type) =>
      switch (type) {
        BuildingType.pastorHouse => [readBible, eat, sleep, homePray, missions],
        BuildingType.house => [practicalHelp, housePray, houseVisit, discipleshipGroup],
        BuildingType.apartment => [
            practicalHelp,
            housePray,
            houseVisit,
            discipleshipGroup,
            blessHousehold,
          ],
        BuildingType.church || BuildingType.cathedral => [sundayService, worship],
        BuildingType.hospital => [medicalHelp, counseling, chapelService],
        BuildingType.school || BuildingType.university => [
            letterToManagement,
            talkDirector,
            valueLecture,
            prayerCircle,
          ],
        BuildingType.cemetery => [funeral, comfort],
        BuildingType.policeStation => [blessPolice, genericPray, witness],
        BuildingType.cityHall => [mayorAudience, prayForPoliticians],
        BuildingType.trainStation => [travel],
        BuildingType.stadium => [majorEvent],
        BuildingType.shop ||
        BuildingType.supermarket ||
        BuildingType.mall ||
        BuildingType.office ||
        BuildingType.skyscraper =>
          [talkBoss, shopping, bless, requestDonation],
        _ => [genericPray, witness, distribute],
      };

  /// The action of [type] with wire type [actionType], if it exists there.
  static GameAction<BuildingModel>? find(BuildingType type, String actionType) {
    for (final a in forType(type)) {
      if (a.type == actionType) return a;
    }
    return null;
  }
}
