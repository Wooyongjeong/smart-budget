import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_budget/features/transactions/receipt_analysis.dart';

void main() {
  test('posts image to local Ollama and parses a draft', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final client = OllamaReceiptAnalysisClient(
      baseUrl: Uri.parse('http://10.55.251.29:11434'),
      model: 'qwen3-vl:2b-instruct-q4_K_M',
      client: MockClient((request) async {
        expect(request.url.path, '/api/chat');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'qwen3-vl:2b-instruct-q4_K_M');
        expect(body['stream'], false);
        expect(body['format'], 'json');
        expect((body['messages'] as List).single['images'], [
          base64Encode(bytes),
        ]);
        return http.Response(
          jsonEncode({
            'message': {
              'content': jsonEncode({
                'items': [
                  {
                    'date': '2026-09-28',
                    'merchant': 'CAFE',
                    'amount': 4500,
                    'suggested_type': 'expense',
                    'payment_hint': null,
                    'category_hint': null,
                    'review_reasons': [],
                  },
                ],
              }),
            },
          }),
          200,
        );
      }),
    );
    final result = await client.analyze(
      householdId: 'household',
      bytes: bytes,
      contentType: 'image/png',
    );
    expect(result.items.single.amount, 4500);
    expect(result.draftId, startsWith('local-'));
  });

  test('rejects malformed provider items', () async {
    final client = OllamaReceiptAnalysisClient(
      baseUrl: Uri.parse('http://10.55.251.29:11434'),
      model: 'qwen3-vl:2b-instruct-q4_K_M',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': {'content': '{"items":[{"amount":-5}]}'},
          }),
          200,
        ),
      ),
    );
    expect(
      client.analyze(
        householdId: 'household',
        bytes: Uint8List.fromList([1]),
        contentType: 'image/png',
      ),
      throwsA(isA<ReceiptAnalysisException>()),
    );
  });
}
