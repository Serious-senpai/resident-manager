import "dart:convert";

import "package:async_locks/async_locks.dart";
import "package:http/http.dart";

class HTTPClient {
  static final Uri baseUrl = Uri(
    scheme: "https",
    host: "apartment-management.azurewebsites.net",
  );

  final Client _http;
  final _semaphore = Semaphore(5);

  HTTPClient({Client? client}) : _http = client ?? Client();

  /// Perform a HTTP GET request
  Future<Response> get(Uri url, {Map<String, String>? headers}) => _semaphore.run(() => _http.get(url, headers: headers));

  /// Perform a HTTP POST request
  Future<Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _semaphore.run(() => _http.post(url, headers: headers, body: body, encoding: encoding));

  Future<Response> apiGet(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) =>
      get(baseUrl.replace(path: path, queryParameters: queryParameters), headers: headers);

  Future<Response> apiPost(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      post(
        baseUrl.replace(path: path, queryParameters: queryParameters),
        headers: headers,
        body: body,
        encoding: encoding,
      );

  /// Cancel all running operations
  void cancelAll() => _semaphore.cancelAll();
}
