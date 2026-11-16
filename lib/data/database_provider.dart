import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// The one open database, shared by every controller. main() opens it before
/// the first frame and overrides this provider with the result.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('databaseProvider must be overridden at start'),
);
