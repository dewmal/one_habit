import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_database.dart';
import 'data/database_provider.dart';
import 'data/startup.dart';
import 'i18n/language.dart';
import 'app/app_root.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Open the encrypted database once, before the first frame.
  final database = await AppDatabase.open();
  final startup = await Startup.load(database);
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        startupOverride(startup),
      ],
      child: const HabitAgentApp(),
    ),
  );
}

class HabitAgentApp extends ConsumerWidget {
  const HabitAgentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    return MaterialApp(
      title: tr('app.name', language),
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: const AppRoot(),
    );
  }
}
