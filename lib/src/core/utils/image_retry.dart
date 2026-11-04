import 'dart:async';
import 'dart:ui';

import 'package:flame/cache.dart';

/// Loads [asset]; when that fails or hangs (on the web a slow or broken
/// download), tries again in the background until it arrives – [onLoaded]
/// then swaps the drawn fallback shapes for the real sprites (playtest
/// 2026-11-01: one hiccup from GitHub Pages left the city without houses
/// and people for the whole session).
Future<Image?> loadImageWithRetry(
  Images images,
  String asset,
  void Function(Image image) onLoaded, {
  Duration timeout = const Duration(seconds: 20),
  Duration firstWait = const Duration(seconds: 2),
  Duration maxWait = const Duration(seconds: 30),
}) async {
  var done = false;
  var tries = 0;

  Future<Image?> attempt() async {
    // A failed load stays in the cache under its key – each retry uses a
    // fresh one. A hanging download may still arrive later: then it counts.
    final load = images.load(asset, key: tries++ == 0 ? asset : '$asset#$tries');
    unawaited(load.then((image) {
      if (!done) {
        done = true;
        onLoaded(image);
      }
    }, onError: (Object _) {}));
    try {
      return await load.timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  final image = await attempt();
  if (image != null) return image;
  unawaited(() async {
    var wait = firstWait;
    while (!done) {
      await Future<void>.delayed(wait);
      if (done || await attempt() != null) return;
      wait = wait * 2 > maxWait ? maxWait : wait * 2;
    }
  }());
  return null;
}
