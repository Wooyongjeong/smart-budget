import 'dart:typed_data';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class ReceiptAnalysisItem {
  const ReceiptAnalysisItem({
    required this.date,
    required this.merchant,
    required this.amount,
    required this.suggestedType,
    required this.paymentHint,
    required this.categoryHint,
    required this.reviewReasons,
  });

  factory ReceiptAnalysisItem.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    return ReceiptAnalysisItem(
      date: json['date'] as String?,
      merchant: json['merchant'] as String?,
      amount: amount is num ? amount.toInt() : null,
      suggestedType: json['suggested_type'] as String? ?? 'unknown',
      paymentHint: json['payment_hint'] as String?,
      categoryHint: json['category_hint'] as String?,
      reviewReasons: (json['review_reasons'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  final String? date;
  final String? merchant;
  final int? amount;
  final String suggestedType;
  final String? paymentHint;
  final String? categoryHint;
  final List<String> reviewReasons;
}

class ReceiptAnalysisResult {
  const ReceiptAnalysisResult({required this.draftId, required this.items});

  factory ReceiptAnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('invalid_provider_response');
    }
    return ReceiptAnalysisResult(
      draftId: json['draft_id'] as String? ?? '',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ReceiptAnalysisItem.fromJson)
          .toList(growable: false),
    );
  }

  final String draftId;
  final List<ReceiptAnalysisItem> items;
}

abstract interface class ReceiptAnalysisClient {
  Future<ReceiptAnalysisResult> analyze({
    required String householdId,
    required Uint8List bytes,
    required String contentType,
  });
}

class SupabaseReceiptAnalysisClient implements ReceiptAnalysisClient {
  SupabaseReceiptAnalysisClient({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  @override
  Future<ReceiptAnalysisResult> analyze({
    required String householdId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    late final FunctionResponse response;
    try {
      response = await client.functions.invoke(
        'analyze-receipt',
        body: bytes,
        headers: {'content-type': contentType, 'x-household-id': householdId},
      );
    } on FunctionException catch (error) {
      var code = 'network_error';
      if (error.details is String) {
        try {
          final decoded = jsonDecode(error.details as String);
          if (decoded is Map<String, dynamic> && decoded['code'] is String) {
            code = decoded['code'] as String;
          }
        } on FormatException {
          // Keep the transport-specific fallback code.
        }
      }
      throw ReceiptAnalysisException(code);
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('invalid_provider_response');
    }
    if (data['code'] is String && data['code'] != null) {
      throw ReceiptAnalysisException(data['code'] as String);
    }
    return ReceiptAnalysisResult.fromJson(data);
  }
}

class ReceiptAnalysisException implements Exception {
  const ReceiptAnalysisException(this.code);

  final String code;

  @override
  String toString() => 'ReceiptAnalysisException($code)';
}
