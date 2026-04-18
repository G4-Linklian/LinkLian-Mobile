import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/services/api_client.dart';

class ReportRepository {
	final ApiClient apiClient;

	ReportRepository(this.apiClient);

	Future<List<Map<String, dynamic>>> uploadReportImages(List<File> files) async {
		if (files.isEmpty) return [];

		Response<dynamic> response;
		try {
			response = await apiClient.uploadMultipart(
				'/file-storage/upload/institution/report',
				files: files,
				fieldName: 'files',
			);
		} on DioException catch (e) {
			if (e.response?.statusCode == 404) {
				response = await apiClient.uploadMultipart(
					'/file-storage/upload/user/report',
					files: files,
					fieldName: 'files',
				);
			} else {
				rethrow;
			}
		}

		final data = response.data;
		if (data == null) return [];

		final normalizedFiles = <Map<String, dynamic>>[];

		if (data is Map && data['files'] is List) {
			for (final item in data['files'] as List) {
				if (item is Map<String, dynamic>) {
					final url = item['fileUrl'] ?? item['file_url'] ?? item['url'];
					if (url is String && url.isNotEmpty) {
						final fileType =
							item['fileType'] ?? item['file_type'] ?? item['type'] ?? 'png';
						final originalName =
							item['originalName'] ??
							item['original_name'] ??
							item['fileName'] ??
							item['file_name'] ??
							'image.png';

						normalizedFiles.add({
							'url': url,
							'type': fileType,
							'original_name': originalName,
						});
					}
				}
			}
		}

		return normalizedFiles;
	}

	Future<void> createInstitutionReport({
		required int instId,
		required int reporterId,
		required String title,
		required String detail,
		required List<Map<String, dynamic>> reportFiles,
	}) async {
		final payload = <String, dynamic>{
			'inst_id': instId,
			'reporter_id': reporterId,
			'title': title,
			'detail': detail,
			'flag_valid': true,
		};

		// report_file optional: send only when user attached images.
		if (reportFiles.isNotEmpty) {
			payload['report_file'] = {'files': reportFiles};
		}

		try {
			await apiClient.post<Map<String, dynamic>>(
				'/report/institution',
				data: payload,
			);
		} on DioException catch (e) {
			final data = e.response?.data;
			if (data is Map<String, dynamic>) {
				final message = data['message'];
				if (message is String && message.isNotEmpty) {
					throw Exception(message);
				}
				if (message is List && message.isNotEmpty) {
					throw Exception(message.join(', '));
				}
			}
			rethrow;
		}
	}
}
