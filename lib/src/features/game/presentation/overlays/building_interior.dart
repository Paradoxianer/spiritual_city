part of '../game_screen.dart';

// ── Building door ─────────────────────────────────────────────────────────────

/// Data passed to the [BuildingInteriorOverlay] when a building is entered.
class GameBuildingData {
  final BuildingModel building;

  /// Street address at the door, e.g. "Lindenallee 14" (null if unknown).
  final String? address;

  GameBuildingData({required this.building, this.address});
}

/// The door of a residential building: knock 🔔 (faith-based chance). On
/// success the pastor steps inside the walkable room ([InteriorWorld]);
/// always-open buildings skip this and go straight in.
class BuildingInteriorOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const BuildingInteriorOverlay({super.key, required this.game});

  @override
  State<BuildingInteriorOverlay> createState() => _BuildingInteriorOverlayState();
}

class _BuildingInteriorOverlayState extends State<BuildingInteriorOverlay> {
  /// `null` = not knocked yet, `false` = access denied.
  bool? _accessGranted;

  @override
  void initState() {
    super.initState();
    widget.game.buildingActionIndex.addListener(_onBuildingKey);
  }

  @override
  void dispose() {
    widget.game.buildingActionIndex.removeListener(_onBuildingKey);
    super.dispose();
  }

  /// Key 1 knocks.
  void _onBuildingKey() {
    if (widget.game.buildingActionIndex.value == 0 && _accessGranted == null) _attemptKnock();
  }

  void _attemptKnock() {
    final data = widget.game.activeBuildingData;
    if (data == null) return;
    if (widget.game.attemptBuildingAccess(data.building)) {
      widget.game.enterInterior(data.building);
    } else {
      setState(() => _accessGranted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.game.activeBuildingData;
    if (data == null) return const SizedBox.shrink();
    final building = data.building;
    return OverlayShell(
      theme: OverlayTheme.building,
      leading: Text(
        BuildingComponent.buildingEmoji(building.type),
        style: const TextStyle(fontSize: 30),
      ),
      title: _buildTitle(data),
      onClose: () => widget.game.closeBuildingInterior(),
      body: _accessGranted == false ? _buildDeniedScreen() : _buildKnockScreen(building),
    );
  }

  /// Address (a proper name, no translation needed) and the residents.
  Widget _buildTitle(GameBuildingData data) {
    final residents = data.building.residents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.address != null)
          Text(
            data.address!,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        if (residents.isNotEmpty)
          Text(
            residents.map((r) => r.name.split(' ').first).join(' · '),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
          ),
      ],
    );
  }

  Widget _buildKnockScreen(BuildingModel building) {
    final chance = (building.accessChance(widget.game.faith) * 100).round();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚪', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          // Success chance, with the known-house bonus as 🤝.
          Text(
            '🎲 $chance %${building.interactionCount >= 3 ? '  🤝' : ''}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 15),
          ),
          if (building.residents.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildResidentChips(building),
          ],
          const SizedBox(height: 18),
          ActionButton(emoji: '🔔', keyIndex: 1, highlighted: true, onTap: _attemptKnock),
        ],
      ),
    );
  }

  Widget _buildDeniedScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚪😤', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 18),
          ActionButton(emoji: '👋', onTap: () => widget.game.closeBuildingInterior()),
        ],
      ),
    );
  }

  /// Residents with their faith face.
  Widget _buildResidentChips(BuildingModel building) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: building.residents.map((npc) {
        final faithEmoji = npc.faith > 50 ? '✝️' : (npc.faith > 0 ? '😐' : '😔');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(faithEmoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                npc.name.split(' ').first,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Inside: slim HUD and the upgrade panel ────────────────────────────────────

/// Slim bar at the top while inside a building: what it is, how many
/// visits are left, the building's mission and its faith.
class InteriorHud extends StatelessWidget {
  final SpiritWorldGame game;
  const InteriorHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final data = game.activeBuildingData;
    if (data == null) return const SizedBox.shrink();
    final b = data.building;
    final mission = b.activeMission;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: StreamBuilder<int>(
          // Light refresh so dots / mission progress follow the actions.
          stream: Stream.periodic(const Duration(milliseconds: 500), (i) => i),
          builder: (context, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(BuildingComponent.buildingEmoji(b.type), style: const TextStyle(fontSize: 18)),
                if (data.address != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    data.address!,
                    style: TextStyle(
                      color: b.isHomebase ? const Color(0xFFFFD54F) : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (!b.isHomebase) ...[
                  const SizedBox(width: 8),
                  SessionDots(done: b.currentSessionInteractions, max: b.maxSessionInteractions),
                ],
                if (mission != null) ...[
                  const SizedBox(width: 8),
                  Text('📋${mission.actionEmoji} ${mission.progress}/${mission.targetCount}',
                      style: const TextStyle(color: Colors.amber, fontSize: 12)),
                ],
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: game.leaveInterior,
                  child: const Text('🚪', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ⚔️ upgrades at the pastor house's dresser.
class UpgradeOverlay extends StatelessWidget {
  final SpiritWorldGame game;
  const UpgradeOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return OverlayShell(
      theme: OverlayTheme.home,
      leading: const Text('⚔️', style: TextStyle(fontSize: 30)),
      onClose: () => game.overlays.remove('UpgradeOverlay'),
      body: SingleChildScrollView(child: _UpgradePanel(game: game)),
    );
  }
}
