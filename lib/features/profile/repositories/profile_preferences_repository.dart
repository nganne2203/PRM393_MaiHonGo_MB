import 'package:shared_preferences/shared_preferences.dart';

class EditableProfile {
  final String? name;
  final String? avatarPath;
  final DateTime? birthday;
  final String? gender;

  const EditableProfile({
    this.name,
    this.avatarPath,
    this.birthday,
    this.gender,
  });

  bool get hasAnyValue =>
      (name?.trim().isNotEmpty ?? false) ||
      (avatarPath?.trim().isNotEmpty ?? false) ||
      birthday != null ||
      (gender?.trim().isNotEmpty ?? false);

  EditableProfile copyWith({
    String? name,
    String? avatarPath,
    DateTime? birthday,
    String? gender,
  }) {
    return EditableProfile(
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
    );
  }
}

class ProfilePreferencesRepository {
  static const _nameKey = 'profile_name';
  static const _avatarPathKey = 'profile_avatar_path';
  static const _birthdayKey = 'profile_birthday';
  static const _genderKey = 'profile_gender';

  final Future<SharedPreferences> _prefsFuture;

  ProfilePreferencesRepository({Future<SharedPreferences>? prefs})
      : _prefsFuture = prefs ?? SharedPreferences.getInstance();

  Future<EditableProfile> getProfile() async {
    final prefs = await _prefsFuture;
    return EditableProfile(
      name: _emptyToNull(prefs.getString(_nameKey)),
      avatarPath: _emptyToNull(prefs.getString(_avatarPathKey)),
      birthday: DateTime.tryParse(prefs.getString(_birthdayKey) ?? ''),
      gender: _normalizeGender(prefs.getString(_genderKey)),
    );
  }

  Future<EditableProfile> saveProfile(EditableProfile profile) async {
    final prefs = await _prefsFuture;
    await _setOptionalString(prefs, _nameKey, profile.name);
    await _setOptionalString(prefs, _avatarPathKey, profile.avatarPath);
    await _setOptionalString(
      prefs,
      _birthdayKey,
      profile.birthday == null ? null : _dateOnly(profile.birthday!),
    );
    await _setOptionalString(
        prefs, _genderKey, _normalizeGender(profile.gender));
    return getProfile();
  }

  static Future<void> _setOptionalString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, normalized);
  }

  static String? _emptyToNull(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static String? _normalizeGender(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    if (_supportedGenders.contains(normalized)) return normalized;
    return 'prefer_not_to_say';
  }

  static String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static const _supportedGenders = {
    'female',
    'male',
    'non_binary',
    'prefer_not_to_say',
  };
}
