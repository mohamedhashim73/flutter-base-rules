/// Local replacement for playx's dynamic/JSON parsing helpers.
///
/// Drop this file into your project (e.g. `lib/core/utils/parsing_utils.dart`)
/// and replace:
///   import 'package:playx/playx.dart';
/// with:
///   import 'package:kenzyi/core/utils/parsing_utils.dart';
///
/// All functions are null-safe and tolerant of the messy shapes real APIs
/// tend to send (numbers as strings, bools as 0/1 or "true"/"false", etc).
/// If a value is missing or of an unexpected type, the fallback is returned
/// instead of throwing.
library;

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// Safely reads [key] from [source] if [source] is a Map, otherwise null.
Object? _read(Object? source, String key) {
  if (source is Map) {
    return source[key];
  }
  return null;
}

const _arabicIndicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
const _persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// Converts Arabic-Indic (`١٢٣`) and Persian (`۱۲۳`) digits inside [input]
/// to plain English digits (`123`), and normalizes Arabic decimal/thousands
/// separators (`٫` -> `.`, `٬` removed) so the result is safe to feed into
/// [int.tryParse]/[double.tryParse].
///
/// Non-digit characters are left untouched, so it's safe to call on mixed
/// strings like `"السعر ١٢٣.٥٠ جنيه"`.
String _normalizeDigits(String input) {
  var result = input;
  for (var i = 0; i < 10; i++) {
    result = result.replaceAll(_arabicIndicDigits[i], '$i');
    result = result.replaceAll(_persianDigits[i], '$i');
  }
  return result.replaceAll('٫', '.').replaceAll('٬', '');
}

/// Public extension so you can also normalize a string you already have in
/// hand (e.g. a value typed into a TextField), not just values pulled out
/// of JSON via the `asXOr` helpers above, which apply this automatically.
///
/// Example: `"١٢٣".toLocalizedEnglishNumber` -> `"123"`
extension LocalizedNumberX on String {
  String get toLocalizedEnglishNumber => _normalizeDigits(this);
}

/// Same as [LocalizedNumberX.toLocalizedEnglishNumber], but for a [num]
/// (`int`/`double`) you already have — so you can call
/// `.toLocalizedEnglishNumber` regardless of whether the value in hand is
/// still a raw String from the API or has already been parsed into a
/// number, without branching on the type yourself.
///
/// Note: [num.toString] in Dart always produces plain English digits
/// already (Dart never auto-localizes numeric output), so this is a
/// pass-through kept for API symmetry with the String extension above —
/// e.g. `12.toLocalizedEnglishNumber` -> `"12"`, `12.5.toLocalizedEnglishNumber` -> `"12.5"`.
extension LocalizedNumX on num {
  String get toLocalizedEnglishNumber => toString();
}

// ---------------------------------------------------------------------------
// String
// ---------------------------------------------------------------------------

/// Returns the value at [key] as a [String], or [fallback] if missing/null.
///
/// Non-string values (int, double, bool) are stringified rather than
/// discarded, since APIs sometimes send numeric-looking fields as numbers.
String asStringOr(Object? source, String key, {String fallback = ''}) {
  final value = _read(source, key);
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return fallback;
}

/// Returns the value at [key] as a [String], or null if missing/null.
String? asStringOrNull(Object? source, String key) {
  final value = _read(source, key);
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

// ---------------------------------------------------------------------------
// int
// ---------------------------------------------------------------------------

/// Core int coercion used by [asInt], [asIntOr] and [asIntOrNull].
///
/// Handles:
/// - [int] as-is
/// - [double] via truncation (`42.0` -> `42`, `42.9` -> `42`)
/// - [bool] (`true` -> `1`, `false` -> `0`)
/// - [String], including:
///   - plain digits (`"42"`)
///   - Arabic-Indic / Persian digits (`"٤٢"`)
///   - a leading `+`/`-` sign (`"+42"`, `"-42"`)
///   - surrounding whitespace (`" 42 "`)
///   - thousands separators (`"1,234"`, `"1٬234"`)
///   - decimal-looking strings (`"42.0"`, `"1e3"`), truncated like a double
///
/// Returns null if [value] is null or cannot be parsed as a number.
int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is bool) return value ? 1 : 0;
  if (value is String) {
    final normalized = _normalizeDigits(value)
        .trim()
        .replaceAll(',', ''); // strip thousands separators
    if (normalized.isEmpty) return null;

    final asInt = int.tryParse(normalized);
    if (asInt != null) return asInt;

    // Fall back to double parsing for values like "42.0" or "1e3".
    final asDouble = double.tryParse(normalized);
    if (asDouble != null) return asDouble.toInt();

    return null;
  }
  return null;
}

/// Returns the value at [key] as an [int], or [fallback] (default `0`) if
/// missing/invalid.
///
/// Shorthand for the common case — same behavior as [asIntOr], just a
/// shorter name to match how you'd write `asInt(user, "id")` alongside
/// [asStringOr]/[asBoolOr]/etc. Use [asIntOr] if you prefer the explicit
/// "Or" naming, and [asIntOrNull] when you need `null` instead of a
/// fallback.
///
/// Handles values that arrive as a [String] (e.g. `"42"`), a [double]
/// (e.g. `42.0`), a [bool], or localized/thousands-separated strings — see
/// [_parseInt] for the full list of accepted shapes.
///
/// Example:
/// ```dart
/// id: asInt(user, "id"),
/// ```
int asInt(Object? source, String key, {int fallback = 0}) {
  return _parseInt(_read(source, key)) ?? fallback;
}

/// Returns the value at [key] as an [int], or [fallback] if missing/invalid.
///
/// Identical to [asInt] — kept for symmetry with [asStringOr]/[asBoolOr]/etc.
/// naming. Prefer [asInt] for brevity, or this if you like the explicit
/// "Or" suffix.
int asIntOr(Object? source, String key, {int fallback = 0}) {
  return _parseInt(_read(source, key)) ?? fallback;
}

/// Returns the value at [key] as an [int], or null if missing/invalid.
int? asIntOrNull(Object? source, String key) {
  return _parseInt(_read(source, key));
}

// ---------------------------------------------------------------------------
// double
// ---------------------------------------------------------------------------

/// Returns the value at [key] as a [double], or [fallback] if missing/invalid.
double asDoubleOr(Object? source, String key, {double fallback = 0.0}) {
  final value = _read(source, key);
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(_normalizeDigits(value)) ?? fallback;
  return fallback;
}

/// Returns the value at [key] as a [double], or null if missing/invalid.
double? asDoubleOrNull(Object? source, String key) {
  final value = _read(source, key);
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(_normalizeDigits(value));
  return null;
}

// ---------------------------------------------------------------------------
// bool
// ---------------------------------------------------------------------------

/// Returns the value at [key] as a [bool], or [fallback] if missing/invalid.
///
/// Accepts real booleans, `"true"`/`"false"` strings (case-insensitive),
/// and `1`/`0` numbers, since those are all common wire representations.
bool asBoolOr(Object? source, String key, {bool fallback = false}) {
  final value = _read(source, key);
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase().trim();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
    return fallback;
  }
  if (value is num) return value != 0;
  return fallback;
}

/// Returns the value at [key] as a [bool], or null if missing/invalid.
bool? asBoolOrNull(Object? source, String key) {
  final value = _read(source, key);
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase().trim();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
    return null;
  }
  if (value is num) return value != 0;
  return null;
}

// ---------------------------------------------------------------------------
// Map
// ---------------------------------------------------------------------------

/// Returns the value at [key] as a `Map<String, dynamic>`.
///
/// If the key is missing, not a Map, or the map itself needs re-typing
/// (e.g. it comes back as `Map<dynamic, dynamic>` from some JSON decoders),
/// this normalizes it. Falls back to [fallback] (or an empty map) otherwise.
Map<String, dynamic> asMapOr(
  Object? source,
  String key, {
  Map<String, dynamic>? fallback,
}) {
  final value = _read(source, key);
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return fallback ?? <String, dynamic>{};
}

/// Returns the value at [key] as a `Map<String, dynamic>`, or null if
/// missing/not a map.
Map<String, dynamic>? asMapOrNull(Object? source, String key) {
  final value = _read(source, key);
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

// ---------------------------------------------------------------------------
// List
// ---------------------------------------------------------------------------

/// Returns the value at [key] as a `List<dynamic>`, or [fallback]
/// (default: empty list) if missing/not a list.
List<dynamic> asListOr(Object? source, String key, {List<dynamic>? fallback}) {
  final value = _read(source, key);
  if (value is List) return value;
  return fallback ?? <dynamic>[];
}

/// Returns the value at [key] as a `List<dynamic>`, or null if
/// missing/not a list.
List<dynamic>? asListOrNull(Object? source, String key) {
  final value = _read(source, key);
  if (value is List) return value;
  return null;
}

// ---------------------------------------------------------------------------
// num (int or double, whichever fits)
// ---------------------------------------------------------------------------

/// Returns the value at [key] as a [num], or [fallback] if missing/invalid.
/// Useful when a field can legitimately be either an int or a double
/// depending on the payload (e.g. `price`, `rating`, `latitude`).
num asNumOr(Object? source, String key, {num fallback = 0}) {
  final value = _read(source, key);
  if (value == null) return fallback;
  if (value is num) return value;
  if (value is String) return num.tryParse(_normalizeDigits(value)) ?? fallback;
  return fallback;
}

/// Returns the value at [key] as a [num], or null if missing/invalid.
num? asNumOrNull(Object? source, String key) {
  final value = _read(source, key);
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(_normalizeDigits(value));
  return null;
}

// ---------------------------------------------------------------------------
// DateTime
// ---------------------------------------------------------------------------

/// Returns the value at [key] as a [DateTime], or [fallback] if
/// missing/invalid.
///
/// Handles ISO-8601 strings (`"2024-01-30T12:00:00Z"`), and epoch
/// timestamps as either an int/String of milliseconds or seconds
/// (auto-detected by magnitude: values under ~10 billion are treated as
/// seconds, since that's below the epoch-seconds/epoch-millis crossover
/// for any date before the year 2286).
DateTime asDateTimeOr(Object? source, String key, {required DateTime fallback}) {
  return asDateTimeOrNull(source, key) ?? fallback;
}

/// Returns the value at [key] as a [DateTime], or null if missing/invalid.
DateTime? asDateTimeOrNull(Object? source, String key) {
  final value = _read(source, key);
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    final asInt = int.tryParse(value);
    if (asInt != null) return _dateTimeFromEpoch(asInt);
    return null;
  }
  if (value is int) return _dateTimeFromEpoch(value);
  return null;
}

DateTime _dateTimeFromEpoch(int value) {
  // Treat values under 10 billion as seconds, otherwise milliseconds.
  final isSeconds = value.abs() < 10000000000;
  return DateTime.fromMillisecondsSinceEpoch(
    isSeconds ? value * 1000 : value,
    isUtc: true,
  );
}

/// Same as [asDateTimeOr], but converts the result to local time via
/// [DateTime.toLocal]. Use this for display purposes (e.g. "joined on ..."),
/// and prefer [asDateTimeOr] (UTC) when the value will be sent back to an
/// API or compared/stored, to avoid timezone drift.
DateTime asLocalDateTimeOr(Object? source, String key, {required DateTime fallback}) {
  return asDateTimeOrNull(source, key)?.toLocal() ?? fallback;
}

/// Same as [asDateTimeOrNull], but converts the result to local time via
/// [DateTime.toLocal]. Returns null if missing/invalid.
DateTime? asLocalDateTimeOrNull(Object? source, String key) {
  return asDateTimeOrNull(source, key)?.toLocal();
}

// ---------------------------------------------------------------------------
// Duration
// ---------------------------------------------------------------------------

/// Returns the value at [key] as a [Duration], treating the raw number as
/// **seconds** (the common convention for API fields like `expiresIn`).
Duration asDurationOr(Object? source, String key, {Duration fallback = Duration.zero}) {
  final seconds = asIntOrNull(source, key);
  if (seconds == null) return fallback;
  return Duration(seconds: seconds);
}

/// Returns the value at [key] as a [Duration] (in seconds), or null if
/// missing/invalid.
Duration? asDurationOrNull(Object? source, String key) {
  final seconds = asIntOrNull(source, key);
  if (seconds == null) return null;
  return Duration(seconds: seconds);
}

// ---------------------------------------------------------------------------
// Uri
// ---------------------------------------------------------------------------

/// Returns the value at [key] as a [Uri], or null if missing/invalid.
Uri? asUriOrNull(Object? source, String key) {
  final value = asStringOrNull(source, key);
  if (value == null || value.isEmpty) return null;
  return Uri.tryParse(value);
}

/// Returns the value at [key] as a [Uri], or [fallback] if missing/invalid.
Uri asUriOr(Object? source, String key, {required Uri fallback}) {
  return asUriOrNull(source, key) ?? fallback;
}

// ---------------------------------------------------------------------------
// Enum
// ---------------------------------------------------------------------------

/// Matches the string value at [key] against [values] (an enum's `.values`
/// list) by name, case-insensitively. Returns [fallback] if missing/no match.
///
/// Example:
/// ```dart
/// tier: asEnumOr(user, 'tier', UserTier.values, fallback: UserTier.bronze),
/// ```
T asEnumOr<T extends Enum>(
  Object? source,
  String key,
  List<T> values, {
  required T fallback,
}) {
  return asEnumOrNull(source, key, values) ?? fallback;
}

/// Matches the string value at [key] against [values] (an enum's `.values`
/// list) by name, case-insensitively. Returns null if missing/no match.
T? asEnumOrNull<T extends Enum>(Object? source, String key, List<T> values) {
  final raw = asStringOrNull(source, key);
  if (raw == null) return null;
  for (final v in values) {
    if (v.name.toLowerCase() == raw.toLowerCase()) return v;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Nested objects (via a fromJson-style mapper)
// ---------------------------------------------------------------------------

/// Parses the map at [key] into a model [T] using [mapper] (typically
/// `Model.fromJson`). Returns null if the key is missing or not a map.
///
/// Example:
/// ```dart
/// medicalProfile: asObjectOrNull(
///   user,
///   'medicalProfile',
///   MedicalProfileModel.fromJson,
/// ),
/// ```
T? asObjectOrNull<T>(
  Object? source,
  String key,
  T Function(Map<String, dynamic> json) mapper,
) {
  final map = asMapOrNull(source, key);
  if (map == null) return null;
  return mapper(map);
}

/// Parses the map at [key] into a model [T] using [mapper], or returns
/// [fallback] if missing/not a map.
T asObjectOr<T>(
  Object? source,
  String key,
  T Function(Map<String, dynamic> json) mapper, {
  required T fallback,
}) {
  return asObjectOrNull(source, key, mapper) ?? fallback;
}

// ---------------------------------------------------------------------------
// Lists of nested objects
// ---------------------------------------------------------------------------

/// Parses the list at [key] into a `List<T>` by running [mapper] over each
/// element that is a Map. Non-map items are skipped rather than throwing.
/// Returns an empty list (or [fallback]) if the key is missing/not a list.
///
/// Example:
/// ```dart
/// addresses: asObjectListOr(user, 'addresses', AddressModel.fromJson),
/// ```
List<T> asObjectListOr<T>(
  Object? source,
  String key,
  T Function(Map<String, dynamic> json) mapper, {
  List<T>? fallback,
}) {
  final list = asListOrNull(source, key);
  if (list == null) return fallback ?? <T>[];
  return list
      .whereType<Map>()
      .map((e) => mapper(Map<String, dynamic>.from(e)))
      .toList();
}

/// Same as [asObjectListOr] but returns null instead of an empty list when
/// the key is missing/not a list (useful for nullable model fields).
List<T>? asObjectListOrNull<T>(
  Object? source,
  String key,
  T Function(Map<String, dynamic> json) mapper,
) {
  final list = asListOrNull(source, key);
  if (list == null) return null;
  return list
      .whereType<Map>()
      .map((e) => mapper(Map<String, dynamic>.from(e)))
      .toList();
}

// ---------------------------------------------------------------------------
// Lists of primitives
// ---------------------------------------------------------------------------

/// Parses the list at [key] into a `List<String>`, coercing each element
/// with [asStringOr]-style rules and dropping anything unparsable.
List<String> asStringListOr(Object? source, String key, {List<String>? fallback}) {
  final list = asListOrNull(source, key);
  if (list == null) return fallback ?? <String>[];
  return list
      .map((e) {
        if (e is String) return e;
        if (e is num || e is bool) return e.toString();
        return null;
      })
      .whereType<String>()
      .toList();
}

/// Parses the list at [key] into a `List<int>`, coercing each element
/// (int, double, numeric String, localized digits) via [_parseInt] and
/// dropping anything unparsable.
List<int> asIntListOr(Object? source, String key, {List<int>? fallback}) {
  final list = asListOrNull(source, key);
  if (list == null) return fallback ?? <int>[];
  return list.map(_parseInt).whereType<int>().toList();
}

/// Parses the list at [key] into a `List<double>`, coercing each element
/// (int, double, numeric String) and dropping anything unparsable.
List<double> asDoubleListOr(Object? source, String key, {List<double>? fallback}) {
  final list = asListOrNull(source, key);
  if (list == null) return fallback ?? <double>[];
  return list
      .map((e) {
        if (e is double) return e;
        if (e is int) return e.toDouble();
        if (e is String) return double.tryParse(e);
        return null;
      })
      .whereType<double>()
      .toList();
}