import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/core/models/visual_schedule.dart';

/// FR13 — the merge that keeps a teacher and a parent editing the same child's
/// schedule in sync without clobbering each other, and never lets two activities
/// share a time slot.
void main() {
  ScheduleItem item(String time, String end, String label) =>
      ScheduleItem(time: time, endTime: end, label: label);

  test('an activity added by the other role survives this save', () {
    final reading = item('09:00', '10:00', 'Reading');
    final lunch = item('12:00', '13:00', 'Lunch');

    // Parent opened with [reading], added lunch. Teacher meanwhile added music.
    final music = item('10:00', '11:00', 'Music');
    final merged = reconcileScheduleItems(
      baseline: [reading],
      draft: [reading, lunch],
      server: [reading, music], // freshest server copy
    );

    expect(merged, containsAll([reading, music, lunch]));
    expect(merged.length, 3);
    // Sorted by start time.
    expect(merged.map((e) => e.label), ['Reading', 'Music', 'Lunch']);
  });

  test('an added activity overlapping a concurrent one is rejected', () {
    final reading = item('09:00', '10:00', 'Reading');
    final clash = item('09:30', '10:30', 'Therapy');
    final music = item('09:15', '09:45', 'Music'); // added by other role

    expect(
      () => reconcileScheduleItems(
        baseline: [reading],
        draft: [reading, clash],
        server: [reading, music],
      ),
      throwsA(isA<ScheduleConflictException>()),
    );
  });

  test('an item the editor removed is dropped from the server copy', () {
    final reading = item('09:00', '10:00', 'Reading');
    final lunch = item('12:00', '13:00', 'Lunch');

    final merged = reconcileScheduleItems(
      baseline: [reading, lunch],
      draft: [lunch], // removed reading
      server: [reading, lunch],
    );

    expect(merged, [lunch]);
  });

  test('re-adding an identical item is a no-op (no duplicate, no clash)', () {
    final reading = item('09:00', '10:00', 'Reading');

    final merged = reconcileScheduleItems(
      baseline: const [],
      draft: [reading],
      server: [reading], // already there
    );

    expect(merged, [reading]);
  });
}
