import "dart:convert";
import "dart:io";
import "dart:ui";

import "package:async_locks/async_locks.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:http/http.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:pinenacl/x25519.dart";

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

  Future<bool> validate({required ApplicationState state}) async {
    final response = await state.http.apiPost(
      isAdmin ? "/api/v1/admin/login" : "/api/v1/login",
      headers: constructHeaders(await state.serverKey()),
    );

    if (response.statusCode == 401) {
      // Invalid server public key
      state.invalidateServerKey();
      return await validate(state: state); // Recursive retry
    }

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
        // Do not change to `await file.exists()`: https://github.com/flutter/flutter/issues/75249
        if (file.existsSync()) {
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

  static Future<_Authorization?> prepare({required ApplicationState state}) async {
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

    if (auth != null && await auth.validate(state: state)) {
      return auth;
    }

    return null;
  }
}

class ApplicationState {
  final HTTPClient http;

  final FlutterLocalization localization = FlutterLocalization.instance;
  final List<void Function(Locale?)> _onTranslationCallbacks = <void Function(Locale?)>[];

  _Authorization? _authorization;
  PublicAuthorization? get authorization => _authorization;

  PublicKey? _serverKey;

  Future<PublicKey> serverKey() async {
    Future<PublicKey> fetcher() async {
      final response = await http.apiGet("/api/v1/key");
      return PublicKey(base64.decode(utf8.decode(response.bodyBytes)));
    }

    return _serverKey ??= await fetcher();
  }

  void invalidateServerKey() {
    _serverKey = null;
  }

  ApplicationState({Client? client}) : http = HTTPClient(client: client ?? Client()) {
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
    final result = await auth.validate(state: this);
    _authorization = result ? auth : null;

    return result;
  }

  Future<void> deauthorize() async {
    await _authorization?.removeAuthData();
    _authorization = null;
  }

  Future<Map<String, String>?> authorizationHeaders() async {
    return _authorization?.constructHeaders(await serverKey());
  }

  Future<void> prepare() async {
    _authorization = await _Authorization.prepare(state: this);
  }

  void pushTranslationCallback(void Function(Locale?) callback) {
    _onTranslationCallbacks.add(callback);
  }

  void popTranslationCallback() {
    _onTranslationCallbacks.removeLast();
  }
}
