import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/i18n/app_strings.dart';
import 'spirit_world_game.dart';

/// Share the game (social media, messenger): a picture of the city as
/// it is now plus the progress and the link.
class ShareProgress {
  static const String url = 'https://paradoxianer.github.io/spiritual_city/';

  /// The post in the player's language – outside the game, where whoever
  /// reads it does not know the game's emoji (playtest 2026-11-04).
  static String text(SpiritWorldGame g) {
    final p = g.progress;
    String t(String k) => AppStrings.get('share.$k');
    final awakened = p.awakenedQuarters.length;
    final free = p.celebratedQuarters.length;
    return '🏙️✝️ ${t('title').replaceAll('{day}', '${p.dayStats.day}')}\n'
        '✝️ ${p.npcsConverted} ${t('converted')}\n'
        '⛪ ${p.church.members.length} ${t('church')}\n'
        '${awakened > 0 ? '🔥 $awakened ${t('awakened')}\n' : ''}'
        '${free > 0 ? '🌐 $free ${t('prayedFree')}\n' : ''}'
        '${t('play')} $url';
  }

  /// Shares [text] and, when [shot] is on screen, a picture of it.
  ///
  /// Without a share sheet (desktop browser) the picture is downloaded and
  /// the text with the link goes to the clipboard: 🖼️⬇️ 📋✅.
  static Future<void> share(SpiritWorldGame g, {GlobalKey? shot, Rect? origin}) async {
    final files = <XFile>[];
    final png = await _capture(shot);
    if (png != null) {
      files.add(XFile.fromData(png, mimeType: 'image/png', name: 'spiritworld-city.png'));
    }
    final result = await SharePlus.instance.share(ShareParams(
      text: text(g),
      files: files.isEmpty ? null : files,
      fileNameOverrides: files.isEmpty ? null : ['spiritworld-city.png'],
      sharePositionOrigin: origin,
    ));
    if (result.status == ShareResultStatus.unavailable) {
      await Clipboard.setData(ClipboardData(text: text(g)));
      g.lootPickupMessage.value = '${files.isEmpty ? '' : '🖼️⬇️ '}📋✅';
    }
  }

  static Future<Uint8List?> _capture(GlobalKey? key) async {
    final ctx = key?.currentContext;
    final boundary = ctx?.findRenderObject();
    if (ctx == null || boundary is! RenderRepaintBoundary) return null;
    try {
      final ratio = MediaQuery.devicePixelRatioOf(ctx).clamp(1.0, 2.0);
      final image = await boundary.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null; // the link alone is fine
    }
  }
}
