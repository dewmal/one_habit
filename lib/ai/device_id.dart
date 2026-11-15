import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A random id made once per install. The gateway uses it only for the hourly
/// rate limit. It is not tied to a person and is never sent anywhere else.
Future<String> loadOrCreateDeviceId({
  FlutterSecureStorage storage = const FlutterSecureStorage(),
}) async {
  const key = 'habit_agent_device_id';
  try {
    final existing = await storage.read(key: key);
    if (existing != null && existing.isNotEmpty) return existing;
  } catch (_) {
    // Storage can fail on some devices. A fresh id for this run is still safe.
  }

  final random = Random.secure();
  final id = List<int>.generate(
    16,
    (_) => random.nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  try {
    await storage.write(key: key, value: id);
  } catch (_) {}
  return id;
}
