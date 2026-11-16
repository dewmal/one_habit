import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

enum GatewayState { checking, online, offline, notConfigured }

/// Pings the gateway's GET /health and keeps the result. Every check is
/// logged with debugPrint, so it shows in `flutter logs` and `adb logcat`
/// (tag "flutter"), release builds included.
class ConnectionStatus extends Notifier<GatewayState> {
  Timer? _timer;

  @override
  GatewayState build() {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => check());
    Future.microtask(check);
    return gatewayUrl.isEmpty
        ? GatewayState.notConfigured
        : GatewayState.checking;
  }

  /// The gateway URL ends in /chat; health sits next to it.
  static Uri healthUri(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.endsWith('/chat')
        ? uri.path.substring(0, uri.path.length - 5)
        : uri.path;
    return uri.replace(path: '$path/health');
  }

  Future<void> check() async {
    if (gatewayUrl.isEmpty) {
      debugPrint(
        'Connection: GATEWAY_URL is not set (build without --dart-define)',
      );
      state = GatewayState.notConfigured;
      return;
    }
    final uri = healthUri(gatewayUrl);
    final watch = Stopwatch()..start();
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        debugPrint('Connection: online $uri (${watch.elapsedMilliseconds} ms)');
        state = GatewayState.online;
      } else {
        debugPrint('Connection: $uri answered HTTP ${res.statusCode}');
        state = GatewayState.offline;
      }
    } on Object catch (e) {
      debugPrint('Connection: offline, could not reach $uri ($e)');
      state = GatewayState.offline;
    }
  }
}

const gatewayUrl = String.fromEnvironment('GATEWAY_URL');

final connectionProvider = NotifierProvider<ConnectionStatus, GatewayState>(
  ConnectionStatus.new,
);
