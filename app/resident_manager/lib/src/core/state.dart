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
import "models/residents.dart";

class Authorization {
  final String username;
  final String password;
  final bool isAdmin;

  Authorization({required this.username, required this.password, required this.isAdmin});
  Authorization.fromJson(Map<String, dynamic> data)
      : this(
          username: data["username"],
          password: data["password"],
          isAdmin: data["isAdmin"],
        );

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "password": password,
      "isAdmin": isAdmin,
    };
  }

  Future<Resident> validate({required HTTPClient client}) async {
    final response = await client.apiPost(
      "/api/login",
      queryParameters: {"isAdmin": isAdmin ? "true" : "false"},
      headers: {"Username": username, "Password": password},
    );
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      await withLoginFile(
        (file) async {
          await file.writeAsString(json.encode(toJson()));
        },
      );

      return Resident.fromJson(data["resident"]);
    } else {
      throw AuthorizationError(data["error"]);
    }
  }

  static final _withLoginFileLock = Lock();

  static Future<T?> withLoginFile<T>(Future<T?> Function(File) callback) async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final file = File(join(cacheDir.absolute.path, "login.json"));

      return await _withLoginFileLock.run(() => callback(file));
    } on MissingPlatformDirectoryException {
      return null;
    }
  }

  static Future<Authorization?> construct({required HTTPClient client}) {
    return withLoginFile(
      (file) async {
        // Do not change to `await file.exists()`: https://github.com/flutter/flutter/issues/75249
        if (file.existsSync()) {
          final data = json.decode(await file.readAsString());
          final username = data["username"];
          final password = data["password"];
          final isAdmin = data["isAdmin"];

          final auth = Authorization(username: username, password: password, isAdmin: isAdmin);
          try {
            await auth.validate(client: client);
            return auth;
          } on AuthorizationError {
            await withLoginFile((file) => file.delete());

            return null;
          }
        }

        return null;
      },
    );
  }
}

class ApplicationState {
  final _http = HTTPClient();

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

  Future<void> prepare() async {
    _authorization = await Authorization.construct(client: _http);
  }

  void pushTranslationCallback(void Function(Locale?) callback) {
    _onTranslationCallbacks.add(callback);
  }

  void popTranslationCallback() {
    _onTranslationCallbacks.removeLast();
  }
}
