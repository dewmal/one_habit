import 'package:flutter_test/flutter_test.dart';
import 'package:one_preccent/plugins/fitness_plugin.dart';

void main() {
  test('Fitness plugin has three levels and five stages', () {
    expect(fitnessPlugin.levels.map((l) => l.id), [
      'beginner',
      'building',
      'ready',
    ]);
    expect(fitnessPlugin.stages.length, 5);
    expect(fitnessPlugin.healthCheck, isNotNull);
  });
}
