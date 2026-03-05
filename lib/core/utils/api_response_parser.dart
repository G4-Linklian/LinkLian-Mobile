class ApiResponseParser {
  ApiResponseParser._();

  static T? parseObject<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response is Map ? response['data'] : null;
    if (data == null) return null;
    if (data is Map<String, dynamic>) return fromJson(data);
    return null;
  }

  static List<T> parseList<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response is Map ? response['data'] : null;
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }

  static bool parseSuccess(dynamic response) {
    if (response is Map) {
      return response['success'] == true;
    }
    return false;
  }
}
