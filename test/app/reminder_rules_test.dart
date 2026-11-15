import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/rules.dart';

const _t21 = TimeOfDay(hour: 21, minute: 0);
const _t07 = TimeOfDay(hour: 7, minute: 0);

void main() {
  test('quiet hours cross midnight: 9 PM to 7 AM', () {
    expect(
      inQuietHours(const TimeOfDay(hour: 22, minute: 0), _t21, _t07),
      isTrue,
    );
    expect(
      inQuietHours(const TimeOfDay(hour: 6, minute: 59), _t21, _t07),
      isTrue,
    );
    expect(
      inQuietHours(const TimeOfDay(hour: 7, minute: 0), _t21, _t07),
      isFalse,
    );
    expect(
      inQuietHours(const TimeOfDay(hour: 12, minute: 0), _t21, _t07),
      isFalse,
    );
  });

  test('a reminder never goes over the daily limit or into quiet hours', () {
    bool can({required TimeOfDay now, required int sent}) => canSendReminder(
      now: now,
      sentToday: sent,
      dailyLimit: 2,
      quietStart: _t21,
      quietEnd: _t07,
    );

    expect(can(now: const TimeOfDay(hour: 12, minute: 0), sent: 1), isTrue);
    expect(can(now: const TimeOfDay(hour: 12, minute: 0), sent: 2), isFalse);
    expect(can(now: const TimeOfDay(hour: 23, minute: 0), sent: 0), isFalse);
  });
}
