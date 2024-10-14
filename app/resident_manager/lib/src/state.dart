import "dart:convert";
import "dart:io";
import "dart:ui";

import "package:async_locks/async_locks.dart";
import "package:flutter/foundation.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:http/http.dart";
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

  Future<bool> validate({
    required ApplicationState state,
    required bool remember,
  }) async {
    final response = await state.post(
      isAdmin ? "/api/v1/admin/login" : "/api/v1/login",
      headers: constructHeaders(),
      authorize: false,
    );

    final result = response.statusCode < 400;
    if (result) {
      if (!isAdmin) {
        resident = Resident.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }

      if (remember) {
        await _withLoginFile((file) => file.writeAsString(json.encode(toJson())));
      } else {
        await removeAuthData();
      }
    }

    return result;
  }

  Future<void> removeAuthData() async {
    await _withLoginFile(
      (file) async {
        // `await file.exists()` hang in flutter test: https://github.com/flutter/flutter/issues/75249
        final exists = Platform.environment.containsKey("FLUTTER_TEST") ? file.existsSync() : await file.exists();
        if (exists) {
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
        // `await file.exists()` hang in flutter test: https://github.com/flutter/flutter/issues/75249
        final exists = Platform.environment.containsKey("FLUTTER_TEST") ? file.existsSync() : await file.exists();
        if (exists) {
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

    // For the authorization data to exist in the file, `remember` must have been set to `true`.
    if (auth != null && await auth.validate(state: state, remember: true)) {
      return auth;
    }

    return null;
  }
}

class ApplicationState {
  static final baseUrl = kDebugMode ? Uri.http("localhost:8000") : Uri.https("resident-manager.azurewebsites.net");

  final HTTPClient http;

  final localization = FlutterLocalization.instance;
  final _onTranslationCallbacks = <void Function(Locale?)>[];
  final extras = <Object, Object?>{};

  _Authorization? _authorization;
  PublicAuthorization? get authorization => _authorization;

  ApplicationState({Client? client}) : http = HTTPClient(client: client ?? Client()) {
    print("Using base API URL $baseUrl"); // ignore: avoid_print

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

  Future<bool> authorize({
    required String username,
    required String password,
    required bool isAdmin,
    required bool remember,
  }) async {
    final auth = _Authorization(username: username, password: password, isAdmin: isAdmin);
    final result = await auth.validate(state: this, remember: remember);
    _authorization = result ? auth : null;

    return result;
  }

  Future<void> deauthorize() async {
    await _authorization?.removeAuthData();
    _authorization = null;
  }

  void _attachAuthorizationHeaders(Map<String, String> headers) {
    final auth = _authorization;
    if (auth != null) {
      headers.addAll(auth.constructHeaders());
    }
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

  Future<Response> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool authorize = true,
  }) async {
    headers ??= {};
    if (authorize) _attachAuthorizationHeaders(headers);

    var response = await http.get(
      baseUrl.replace(path: path, queryParameters: queryParameters),
      headers: headers,
    );

    return response;
  }

  Future<Response> post(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool authorize = true,
  }) async {
    headers ??= {};
    if (authorize) _attachAuthorizationHeaders(headers);

    var response = await http.post(
      baseUrl.replace(path: path, queryParameters: queryParameters),
      headers: headers,
      body: body,
      encoding: encoding,
    );

    return response;
  }
}
