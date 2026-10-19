import 'package:flutter_test/flutter_test.dart';
import 'package:yuitodo/core/notifications/reminder_sounds.dart';

void main() {
  test('default maps to the system channel and no raw sound', () {
    final option = reminderSoundFor(null);
    expect(option.channelId, 'task_reminders');
    expect(option.sound, isNull);
  });

  test('every option uses a unique channel id', () {
    final ids = reminderSounds.map((option) => option.channelId).toSet();
    expect(ids.length, reminderSounds.length);
  });

  test('known keys map to their bundled raw resource', () {
    expect(reminderSoundFor('chime').rawName, 'yuitodo_chime');
    expect(reminderSoundFor('bell').channelId, 'task_reminders_bell');
  });

  test('unknown keys fall back to the system sound', () {
    expect(reminderSoundFor('missing').key, isNull);
  });
}
