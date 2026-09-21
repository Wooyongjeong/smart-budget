import 'package:supabase_flutter/supabase_flutter.dart';

class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.name,
    this.isMe = false,
  });

  final String id;
  final String name;
  final bool isMe;
}

class HouseholdOverview {
  const HouseholdOverview({
    required this.id,
    required this.name,
    required this.members,
  });

  final String id;
  final String name;
  final List<HouseholdMember> members;
}

class HouseholdException implements Exception {
  const HouseholdException(this.code);

  final String code;

  @override
  String toString() => 'HouseholdException($code)';
}

abstract interface class HouseholdRepository {
  Future<HouseholdOverview> load();
  Future<String> updateDisplayName(String name);
  Future<String> createInvitation(String householdId);
  Future<String> acceptInvitation(String token);
  Future<void> leave(String householdId);
}

class SupabaseHouseholdRepository implements HouseholdRepository {
  SupabaseHouseholdRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;
  String? _preferredHouseholdId;

  @override
  Future<HouseholdOverview> load() async {
    var query = client.from('households').select('id,name');
    if (_preferredHouseholdId != null) {
      query = query.eq('id', _preferredHouseholdId!);
    }
    final households = await query.order('created_at').limit(1);
    if (households.isEmpty) throw const HouseholdException('not_found');

    final household = households.first;
    final householdId = household['id'] as String;
    final memberRows = await client
        .from('household_members')
        .select('id,user_id')
        .eq('household_id', householdId)
        .isFilter('left_at', null)
        .order('joined_at');
    final userIds = memberRows
        .map((row) => row['user_id'] as String)
        .toList(growable: false);
    final profileRows = userIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await client
              .from('profiles')
              .select('user_id,display_name')
              .inFilter('user_id', userIds);
    final names = {
      for (final row in profileRows)
        row['user_id'] as String: (row['display_name'] as String).trim(),
    };
    final currentUserId = client.auth.currentUser?.id;

    return HouseholdOverview(
      id: householdId,
      name: household['name'] as String,
      members: memberRows
          .map(
            (row) => HouseholdMember(
              id: row['id'] as String,
              name: names[row['user_id']]?.isNotEmpty == true
                  ? names[row['user_id']]!
                  : row['user_id'] == currentUserId
                  ? '나'
                  : '배우자',
              isMe: row['user_id'] == currentUserId,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<String> updateDisplayName(String name) async {
    try {
      final value = await client.rpc(
        'update_profile_display_name',
        params: {'p_display_name': name.trim()},
      );
      return value as String;
    } on PostgrestException catch (error) {
      throw HouseholdException(_code(error));
    }
  }

  @override
  Future<String> createInvitation(String householdId) async {
    try {
      final token = await client.rpc(
        'create_invitation',
        params: {'p_household_id': householdId},
      );
      return token as String;
    } on PostgrestException catch (error) {
      throw HouseholdException(_code(error));
    }
  }

  @override
  Future<String> acceptInvitation(String token) async {
    try {
      final householdId = await client.rpc(
        'accept_invitation',
        params: {'p_token': token.trim()},
      );
      _preferredHouseholdId = householdId as String;
      return _preferredHouseholdId!;
    } on PostgrestException catch (error) {
      throw HouseholdException(_code(error));
    }
  }

  @override
  Future<void> leave(String householdId) async {
    try {
      await client.rpc(
        'leave_household',
        params: {'p_household_id': householdId},
      );
      _preferredHouseholdId = null;
    } on PostgrestException catch (error) {
      throw HouseholdException(_code(error));
    }
  }

  String _code(PostgrestException error) {
    const codes = {
      'invitation_invalid',
      'invitation_expired_or_used',
      'already_member',
      'household_full',
      'household_unavailable',
      'forbidden',
    };
    return codes.contains(error.message) ? error.message : 'unexpected';
  }
}
