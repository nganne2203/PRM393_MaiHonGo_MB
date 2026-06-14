import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/profile/repositories/profile_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ProfilePreferencesRepository persists editable profile fields',
      () async {
    SharedPreferences.setMockInitialValues({});
    final repository = ProfilePreferencesRepository();

    await repository.saveProfile(
      EditableProfile(
        name: 'Ngan Nguyen',
        avatarPath: '/tmp/avatar.png',
        birthday: DateTime(2002, 8, 16),
        gender: 'female',
      ),
    );

    final profile = await repository.getProfile();
    expect(profile.name, 'Ngan Nguyen');
    expect(profile.avatarPath, '/tmp/avatar.png');
    expect(profile.birthday, DateTime(2002, 8, 16));
    expect(profile.gender, 'female');
  });

  test('ProfilePreferencesRepository normalizes unknown gender', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = ProfilePreferencesRepository();

    await repository.saveProfile(const EditableProfile(gender: 'mystery'));

    final profile = await repository.getProfile();
    expect(profile.gender, 'prefer_not_to_say');
  });
}
