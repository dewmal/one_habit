import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_preccent/i18n/language.dart';

void main() {
  test('starts in English and toggles to Sinhala and back', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(languageProvider), AppLanguage.en);
    container.read(languageProvider.notifier).toggle();
    expect(container.read(languageProvider), AppLanguage.si);
    container.read(languageProvider.notifier).toggle();
    expect(container.read(languageProvider), AppLanguage.en);
  });

  test('tr returns the text for the language and falls back to English', () {
    expect(tr('lang.label', AppLanguage.en), 'English');
    expect(tr('lang.label', AppLanguage.si), 'සිංහල');
    expect(tr('missing.key', AppLanguage.si), 'missing.key');
  });
}
