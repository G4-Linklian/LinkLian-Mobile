import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/class_feed_model.dart';

class ClassFeedRepository {
  final String baseUrl;
  final Future<String?> Function() getToken;

  ClassFeedRepository({
    required this.baseUrl,
    required this.getToken,
  });

  /// ============================
  /// GET CLASS FEED BY SEMESTER
  /// ============================
  Future<List<ClassFeedModel>> getClassFeed({
    required int semesterId,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token not found');
    }

    final uri = Uri.parse('$baseUrl/feed/class');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'semester_id': semesterId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch class feed (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Unknown error');
    }

    final List data = decoded['data'] as List;

    return data
        .map(
          (json) => ClassFeedModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}