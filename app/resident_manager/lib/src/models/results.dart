/// Represents a result JSON response from the API server.
class Result<T> {
  /// The opcode of the result, note that this is different from the HTTP response code
  final int code;

  /// Additional data sent from the API server
  final T? data;

  Result(this.code, this.data);
}
