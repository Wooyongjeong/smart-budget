import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_budget/features/transactions/receipt_analysis.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  for (final contentType in ['application/json', 'text/plain']) {
    for (final code in ['rate_limited', 'provider_not_configured', 'timeout']) {
      test('preserves $code from a $contentType function error', () async {
        final client = SupabaseClient(
          'https://example.supabase.co',
          'public-key',
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({'code': code}),
              429,
              headers: {'content-type': contentType},
            ),
          ),
        );
        addTearDown(client.dispose);
        await expectLater(
          SupabaseReceiptAnalysisClient(client: client).analyze(
            householdId: 'household',
            bytes: Uint8List.fromList([1]),
            contentType: 'image/png',
          ),
          throwsA(
            isA<ReceiptAnalysisException>().having(
              (error) => error.code,
              'code',
              code,
            ),
          ),
        );
      });
    }
  }
  test('uses network fallback for an unstructured function error', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-key',
      httpClient: MockClient((_) async => http.Response('unavailable', 503)),
    );
    addTearDown(client.dispose);
    await expectLater(
      SupabaseReceiptAnalysisClient(client: client).analyze(
        householdId: 'household',
        bytes: Uint8List.fromList([1]),
        contentType: 'image/png',
      ),
      throwsA(
        isA<ReceiptAnalysisException>().having(
          (error) => error.code,
          'code',
          'network_error',
        ),
      ),
    );
  });
}
