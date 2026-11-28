/// Shared Arabic normalization helpers used across search, map filters,
/// and the offline/hybrid Arabic voice assistant.
class ArabicNormalizer {
  ArabicNormalizer._();

  static final RegExp _alefVariants = RegExp(r'[أإآٱ]');
  static final RegExp _diacritics = RegExp(r'[\u064B-\u065F\u0670\u0640]');

  /// Normalizes Arabic text for accent/hamza/tashkeel-insensitive matching:
  /// - trims and lowercases
  /// - folds alef variants (أ/إ/آ/ٱ -> ا)
  /// - folds alef maqsura (ى -> ي) and taa marbouta (ة -> ه)
  /// - removes diacritics (tashkeel) and tatweel
  static String normalize(String input) => input
      .trim()
      .toLowerCase()
      .replaceAll(_alefVariants, 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll(_diacritics, '');

  /// Returns true if [haystack] contains [needle] after Arabic normalization.
  static bool containsNormalized(String haystack, String needle) {
    final n = normalize(needle);
    if (n.isEmpty) return true;
    return normalize(haystack).contains(n);
  }
}
