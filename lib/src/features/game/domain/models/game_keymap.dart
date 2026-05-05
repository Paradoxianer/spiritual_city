import 'package:flutter/services.dart';

/// A single keyboard-shortcut entry for display in the in-game keymap overlay.
class KeymapEntry {
  /// Human-readable key string, e.g. `"W / ↑"`.
  final String keys;

  /// German description of the action triggered by this key.
  final String action;

  /// Display category, e.g. `"Bewegung"`.
  final String category;

  const KeymapEntry({
    required this.keys,
    required this.action,
    required this.category,
  });
}

/// Central registry of every keyboard shortcut used in the game.
///
/// All key constants are defined here so they can be referenced consistently
/// across all game states (real world, spiritual world, dialog).  The [entries]
/// list is used by [KeymapOverlay] to render the in-game help screen.
class GameKeymap {
  GameKeymap._();

  // ── Movement (both worlds) ─────────────────────────────────────────────────
  static const LogicalKeyboardKey moveUp       = LogicalKeyboardKey.keyW;
  static const LogicalKeyboardKey moveDown     = LogicalKeyboardKey.keyS;
  static const LogicalKeyboardKey moveLeft     = LogicalKeyboardKey.keyA;
  static const LogicalKeyboardKey moveRight    = LogicalKeyboardKey.keyD;
  static const LogicalKeyboardKey moveUpAlt    = LogicalKeyboardKey.arrowUp;
  static const LogicalKeyboardKey moveDownAlt  = LogicalKeyboardKey.arrowDown;
  static const LogicalKeyboardKey moveLeftAlt  = LogicalKeyboardKey.arrowLeft;
  static const LogicalKeyboardKey moveRightAlt = LogicalKeyboardKey.arrowRight;

  // ── Real-world actions ─────────────────────────────────────────────────────
  /// Open the radial interaction menu (also closes it when open).
  static const LogicalKeyboardKey interact    = LogicalKeyboardKey.keyE;

  /// Hold to charge prayer / tap to open radial menu (context-sensitive).
  static const LogicalKeyboardKey action      = LogicalKeyboardKey.space;

  /// Close the current menu, dialog or overlay.
  static const LogicalKeyboardKey close       = LogicalKeyboardKey.escape;

  // ── Radial-menu / dialog / building quick-select (1–6) ────────────────────
  static const LogicalKeyboardKey radial1 = LogicalKeyboardKey.digit1;
  static const LogicalKeyboardKey radial2 = LogicalKeyboardKey.digit2;
  static const LogicalKeyboardKey radial3 = LogicalKeyboardKey.digit3;
  static const LogicalKeyboardKey radial4 = LogicalKeyboardKey.digit4;
  static const LogicalKeyboardKey radial5 = LogicalKeyboardKey.digit5;
  static const LogicalKeyboardKey radial6 = LogicalKeyboardKey.digit6;

  // ── Sprint (real world only) ───────────────────────────────────────────────
  /// Hold Shift to sprint (real world only; same physical key as prayerSize
  /// in spiritual world, but handled separately per world context).
  static const LogicalKeyboardKey sprint    = LogicalKeyboardKey.shiftLeft;
  static const LogicalKeyboardKey sprintAlt = LogicalKeyboardKey.shiftRight;

  // ── Prayer / spiritual world ───────────────────────────────────────────────
  /// Hold Shift to grow the prayer zone (same as joystick held without direction).
  static const LogicalKeyboardKey prayerSize    = LogicalKeyboardKey.shiftLeft;
  static const LogicalKeyboardKey prayerSizeAlt = LogicalKeyboardKey.shiftRight;

  /// Switch prayer mode.
  static const LogicalKeyboardKey switchMode = LogicalKeyboardKey.keyR;

  // ── World toggle ───────────────────────────────────────────────────────────
  static const LogicalKeyboardKey worldToggle = LogicalKeyboardKey.keyQ;

  // ── Overlay ────────────────────────────────────────────────────────────────
  /// Show/hide the keymap overlay.
  static const LogicalKeyboardKey keymapOverlay    = LogicalKeyboardKey.f1;

  /// Alternative key for the keymap overlay (`?` on most keyboards).
  static const LogicalKeyboardKey keymapOverlayAlt = LogicalKeyboardKey.slash;

  /// Toggle the mission board (global shortcut).
  static const LogicalKeyboardKey missionBoard = LogicalKeyboardKey.keyM;

  // ── Display entries (rendered by KeymapOverlay) ────────────────────────────
  static const List<KeymapEntry> entries = [
    // Bewegung
    KeymapEntry(keys: 'W / ↑', action: 'Nach oben bewegen',   category: 'Bewegung'),
    KeymapEntry(keys: 'S / ↓', action: 'Nach unten bewegen',  category: 'Bewegung'),
    KeymapEntry(keys: 'A / ←', action: 'Nach links bewegen',  category: 'Bewegung'),
    KeymapEntry(keys: 'D / →', action: 'Nach rechts bewegen', category: 'Bewegung'),
    KeymapEntry(keys: 'Shift', action: 'Sprinten (erhöht Hunger-Verbrauch)', category: 'Bewegung'),

    // Interaktion (reale Welt)
    KeymapEntry(
      keys: 'Leertaste / E',
      action: 'Radialmenü öffnen / Interagieren',
      category: 'Interaktion',
    ),
    KeymapEntry(
      keys: '1 – 6',
      action: 'Radialmenü / Dialog / Gebäude-Aktion auswählen',
      category: 'Interaktion',
    ),
    KeymapEntry(
      keys: 'Esc',
      action: 'Menü / Dialog schließen',
      category: 'Interaktion',
    ),

    // Unsichtbare Welt
    KeymapEntry(
      keys: 'Leertaste (halten)',
      action: 'Geistlichen Kampf aktivieren',
      category: 'Unsichtbare Welt',
    ),
    KeymapEntry(
      keys: '1 – 4',
      action: 'Gebetsmodus direkt auswählen',
      category: 'Unsichtbare Welt',
    ),

    // Allgemein
    KeymapEntry(
      keys: 'Q / 🙏-Button',
      action: 'Welt wechseln (−10 Glaube)',
      category: 'Allgemein',
    ),
    KeymapEntry(
      keys: 'F1 / ?',
      action: 'Tastenbelegung anzeigen',
      category: 'Allgemein',
    ),
    KeymapEntry(
      keys: 'M',
      action: 'Missionsboard öffnen / schließen',
      category: 'Allgemein',
    ),
  ];
}
