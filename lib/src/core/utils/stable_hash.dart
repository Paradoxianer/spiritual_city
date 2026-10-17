/// Stable string hash (DJB2 variant), independent of Dart's built-in
/// [String.hashCode] – which the language spec does not guarantee to be
/// identical across SDK versions/runs.
///
/// Used wherever a deterministic-forever value must be derived from a stable
/// string id (e.g. an NPC's id) without persisting the derived value itself:
/// [NpcNeed] (Issue #171) and the NPC backstory life-event simulation both
/// rely on this so old saves never need a migration for these fields – they
/// are simply recomputed identically every time.
int stableStringHash(String s) {
  int hash = 5381;
  for (final unit in s.codeUnits) {
    hash = ((hash << 5) + hash + unit) & 0x7fffffff; // hash*33 + c, unsigned
  }
  return hash;
}
