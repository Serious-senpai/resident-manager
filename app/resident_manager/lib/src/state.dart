import "dart:convert";
import "dart:io";
import "dart:ui";

import "package:async_locks/async_locks.dart";
import "package:flutter/foundation.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:http/http.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";

import "http.dart";
import "translations.dart";
import "models/residents.dart";

class ApplicationState {
  /// Base URL for the API server.
  static final baseUrl = kDebugMode ? Uri.http("localhost:8000") : Uri.https("resident-manager-1.azurewebsites.net");

  /// HTTP client to make requests.
  ///
  /// When making request to the API server (see [baseUrl]), it is more convenient to use [get] and [post] instead.
  final HTTPClient http;

  /// [FlutterLocalization] for the application.
  final localization = FlutterLocalization.instance;
  final _onTranslationCallbacks = <void Function(Locale?)>[];

  /// Extra data that is globally available to the entire application.
  final extras = <Object, Object?>{};

  /// Token used for authorization
  String? _bearerToken;

  String? _username;
  String? _password;

  /// Resident logged in as
  Resident? resident;

  bool get loggedIn => _bearerToken != null;
  bool get loggedInAsAdmin => _bearerToken != null && resident == null;
  bool get loggedInAsResident => _bearerToken != null && resident != null;

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
    final response = await post(
      isAdmin ? "/api/v1/admin/login" : "/api/v1/login",
      body: "username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}",
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      authorize: false,
    );

    final result = response.statusCode < 400;
    if (result) {
      // Update state attributes
      _username = username;
      _password = password;

      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      _bearerToken = data["access_token"];
      if (!isAdmin) {
        final response = await get(
          "/api/v1/residents/me",
          headers: {"Authorization": "Bearer $_bearerToken"},
          authorize: false,
        );
        resident = Resident.fromJson(json.decode(utf8.decode(response.bodyBytes))["data"]);
      }

      // Save to login file if required
      if (remember) {
        await _withLoginFile(
          (file) => file.writeAsString(
            json.encode(
              {
                "username": username,
                "password": password,
                "is_admin": isAdmin,
              },
            ),
          ),
        );
      } else {
        await _removeLoginFile();
      }
    }

    return result;
  }

  Future<void> deauthorize() async {
    await _removeLoginFile();
    _bearerToken = null;
    resident = null;
  }

  Future<void> prepare() async {
    String? savedLogin;
    await _withLoginFile(
      (file) async {
        // `await file.exists()` hang in flutter test: https://github.com/flutter/flutter/issues/75249
        if (await file.exists()) {
          savedLogin = await file.readAsString();
        }
      },
    );

    if (savedLogin != null) {
      final data = json.decode(savedLogin!);
      final username = data["username"];
      final password = data["password"];
      final isAdmin = data["is_admin"];

      try {
        // For the authorization data to exist in the file, `remember` must have been set to `true`.
        await authorize(username: username, password: password, isAdmin: isAdmin, remember: true);
      } catch (_) {
        // This method is called at application startup, it must ignore all HTTP exceptions (since network maybe unavailable).
      }
    }
  }

  void pushTranslationCallback(void Function(Locale?) callback) {
    _onTranslationCallbacks.add(callback);
  }

  void popTranslationCallback() {
    _onTranslationCallbacks.removeLast();
  }

  Future<bool> _reauthorize(Response response) async {
    final username = _username, password = _password;
    if (username != null && password != null) {
      try {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final code = data["code"];
        if (code == 401 || code == 402) {
          await authorize(
            username: username,
            password: password,
            isAdmin: code == 401,
            remember: await _withLoginFile((file) => file.exists()) ?? false,
          );
          return true;
        }
      } catch (_) {
        // pass
      }
    }

    return false;
  }

  Future<Response> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool authorize = true,
    int retry = 3,
  }) async {
    headers ??= {};
    if (authorize) {
      headers["Authorization"] = "Bearer $_bearerToken";
    }

    var response = await http.get(
      baseUrl.replace(path: path, queryParameters: queryParameters),
      headers: headers,
    );

    if (retry > 0 && response.statusCode >= 400 && await _reauthorize(response)) {
      return await get(
        path,
        queryParameters: queryParameters,
        headers: headers,
        authorize: authorize,
        retry: retry - 1,
      );
    }

    return response;
  }

  Future<Response> post(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool authorize = true,
    int retry = 3,
  }) async {
    headers ??= {};
    if (authorize) {
      headers["Authorization"] = "Bearer $_bearerToken";
    }

    var response = await http.post(
      baseUrl.replace(path: path, queryParameters: queryParameters),
      headers: headers,
      body: body,
      encoding: encoding,
    );

    if (retry > 0 && response.statusCode >= 400 && await _reauthorize(response)) {
      return await post(
        path,
        queryParameters: queryParameters,
        headers: headers,
        body: body,
        encoding: encoding,
        authorize: authorize,
        retry: retry - 1,
      );
    }

    return response;
  }

  static final _withLoginFileLock = Lock();

  /// Calling [_withLoginFile] again in the [callback] will incur a deadlock
  static Future<T?> _withLoginFile<T>(Future<T?> Function(File) callback) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final cacheDir = await getApplicationCacheDirectory();
      final file = File(join(cacheDir.absolute.path, "login-${packageInfo.version}.json"));

      return await _withLoginFileLock.run(() => callback(file));
    } on MissingPlatformDirectoryException {
      return null;
    }
  }

  static Future<void> _removeLoginFile() async {
    await _withLoginFile(
      (file) async {
        // `await file.exists()` hang in flutter test: https://github.com/flutter/flutter/issues/75249
        if (await file.exists()) {
          await file.delete();
        }
      },
    );
  }
}
