import "dart:convert";
import "dart:io";
import "dart:ui";

import "package:async_locks/async_locks.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";

import "errors.dart";
import "http.dart";
import "translations.dart";

class Authorization {
  final String username;
  final String password;
  final bool isAdmin;

  Authorization({required this.username, required this.password, required this.isAdmin});
  Authorization.fromJson(Map<String, dynamic> data)
      : this(
          username: data["username"],
          password: data["password"],
          isAdmin: data["is_admin"],
        );

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
      headers: {"Username": username, "Password": password},
    );

    final result = response.statusCode < 400;
    if (result) {
      await _withLoginFile((file) => file.writeAsString(json.encode(toJson())));
    }

    return result;
  }

  static final _withLoginFileLock = Lock();

  static Future<T?> _withLoginFile<T>(Future<T?> Function(File) callback) async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final file = File(join(cacheDir.absolute.path, "login.json"));

      return await _withLoginFileLock.run(() => callback(file));
    } on MissingPlatformDirectoryException {
      return null;
    }
  }

  static Future<Authorization?> construct({required HTTPClient client}) {
    return _withLoginFile(
      (file) async {
        // Do not change to `await file.exists()`: https://github.com/flutter/flutter/issues/75249
        if (file.existsSync()) {
          final data = json.decode(await file.readAsString());
          final username = data["username"];
          final password = data["password"];
          final isAdmin = data["is_admin"];

          final auth = Authorization(username: username, password: password, isAdmin: isAdmin);
          try {
            await auth.validate(client: client);
            return auth;
          } on AuthorizationError {
            await _withLoginFile((file) => file.delete());

            return null;
          }
        }

        return null;
      },
    );
  }
}

class ApplicationState {
  final http = HTTPClient();

  final FlutterLocalization localization = FlutterLocalization.instance;
  final List<void Function(Locale?)> _onTranslationCallbacks = <void Function(Locale?)>[];

  Authorization? _authorization;
  Authorization? get authorization => _authorization;

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

  Future<bool> authorize(Authorization auth) async {
    final result = await auth.validate(client: http);
    if (result) {
      _authorization = auth;
    }

    return result;
  }

  Future<void> prepare() async {
    _authorization = await Authorization.construct(client: http);
  }

  void pushTranslationCallback(void Function(Locale?) callback) {
    _onTranslationCallbacks.add(callback);
  }

  void popTranslationCallback() {
    _onTranslationCallbacks.removeLast();
  }
}
