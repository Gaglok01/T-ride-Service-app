/// Human-readable message from API / repository errors.
String apiErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  final s = error.toString().trim();
  if (s.isEmpty) return fallback;
  // Strip common Exception wrapper noise when unhelpful
  if (s == 'Exception' || s == 'Exception:') return fallback;
  return s;
}
