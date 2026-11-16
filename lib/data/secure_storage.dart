import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The one secure storage for the database key and the device id.
///
/// On iOS the Keychain can outlive the app, and can move to a new phone in a
/// backup. `first_unlock_this_device` keeps the key on this phone only. A
/// fresh install that finds an old key but no database file just makes a new
/// empty database with it.
const secureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);
