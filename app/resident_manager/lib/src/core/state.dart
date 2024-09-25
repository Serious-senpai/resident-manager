import "dart:convert";
import "dart:io";
import "dart:ui";

import "package:async_locks/async_locks.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";

import "http.dart";
import "translations.dart";
import "models/auth.dart";
import "models/residents.dart";

class PublicAuthorization extends Authorization {
  final bool isAdmin;
  Resident? resident;

  PublicAuthorization({required super.username, required super.password, required this.isAdmin});
}

class _Authorization extends PublicAuthorization {
  _Authorization({required super.username, required super.password, required super.isAdmin});

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "password": password,
      "is_admin": isAdmin,
    };
  }

  Future<bool> validate({required HTTPClient client}) async {
    final response = await client.apiPost(
      isAdmin ? "/api/admin/login" : "/api/login",
      headers: headers,
    );

    final result = response.statusCode < 400;

    // Do not cache admin data
    if (result && !isAdmin) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      resident = Resident.fromJson(data);

      await _withLoginFile((file) => file.writeAsString(json.encode(toJson())));
    } else {
      await removeAuthData();
    }

    return result;
  }

  Future<void> removeAuthData() async {
    await _withLoginFile(
      (file) async {
        if (await file.exists()) {
          await file.delete();
        }
      },
    );
  }

  static final _withLoginFileLock = Lock();

  static Future<T?> _withLoginFile<T>(Future<T?> Function(File) callback) async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final file = File(join(cacheDir.absolute.path, "login.json"));

      // Watch out for deadlocks! _withLoginFile<T> mustn't be invoked again in `callback`.
      return await _withLoginFileLock.run(() => callback(file));
    } on MissingPlatformDirectoryException {
      return null;
    }
  }

  static Future<_Authorization?> prepare({required HTTPClient client}) async {
    final auth = await _withLoginFile(
      (file) async {
        // Do not change to `await file.exists()`: https://github.com/flutter/flutter/issues/75249
        if (file.existsSync()) {
          final data = json.decode(await file.readAsString());
          final username = data["username"];
          final password = data["password"];
          final isAdmin = data["is_admin"];

          try {
            return _Authorization(username: username, password: password, isAdmin: isAdmin);
          } catch (_) {
            return null;
          }
        }
      },
    );

    if (auth != null && await auth.validate(client: client)) {
      return auth;
    }

    return null;
  }
}

class ApplicationState {
  final http = HTTPClient();

  final FlutterLocalization localization = FlutterLocalization.instance;
  final List<void Function(Locale?)> _onTranslationCallbacks = <void Function(Locale?)>[];

  _Authorization? _authorization;
  PublicAuthorization? get authorization => _authorization;

  ApplicationState() {
    localization.init(
      mapLocales: [
        const MapLocale("en", AppLocale.EN),
        const MapLocale("vi", AppLocale.VI),
      ],
      initLanguageCode: "vi",
    );
    localization.onTranslatedLanguage = (Locale? locale) {
      for (final callback in _onTranslationCallbacks) {
        callback(locale);
      }
    };
  }

  Future<bool> authorize({required String username, required String password, required bool isAdmin}) async {
    final auth = _Authorization(username: username, password: password, isAdmin: isAdmin);
    final result = await auth.validate(client: http);
    _authorization = result ? auth : null;

    return result;
  }

  Future<void> deauthorize() async {
    await _authorization?.removeAuthData();
    _authorization = null;
  }

  Future<void> prepare() async {
    _authorization = await _Authorization.prepare(client: http);
  }

  void pushTranslationCallback(void Function(Locale?) callback) {
    _onTranslationCallbacks.add(callback);
  }

  void popTranslationCallback() {
    _onTranslationCallbacks.removeLast();
  }
}
