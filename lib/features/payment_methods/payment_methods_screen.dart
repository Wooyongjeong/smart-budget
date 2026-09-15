import 'package:flutter/material.dart';

import '../transactions/transaction_repository.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({
    super.key,
    required this.repository,
    required this.contextData,
    this.onReturnToEntry,
  });

  final TransactionRepository repository;
  final HouseholdContext contextData;
  final VoidCallback? onReturnToEntry;

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late final List<PaymentMethodOption> methods = [
    ...widget.contextData.paymentMethods,
  ];
  bool saving = false;

  static const kinds = <String, String>{
    'cash': '현금',
    'bank': '계좌',
    'debit_card': '체크카드',
    'credit_card': '신용카드',
  };

  Future<void> add() async {
    final result = await showDialog<_PaymentMethodDraft>(
      context: context,
      builder: (context) =>
          _PaymentMethodDialog(members: widget.contextData.members),
    );
    if (result == null || !mounted) return;
    setState(() => saving = true);
    try {
      final method = await widget.repository.addPaymentMethod(
        widget.contextData.householdId,
        result.kind,
        result.name,
        result.ownerMemberId,
      );
      if (!mounted) return;
      setState(() => methods.add(method));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('결제 수단을 등록했어요.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결제 수단을 등록하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> archive(PaymentMethodOption method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결제 수단을 보관할까요?'),
        content: Text('${method.name}은(는) 새 거래 입력에서 숨겨져요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('보관'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.archivePaymentMethod(
        widget.contextData.householdId,
        method.id,
      );
      if (mounted) {
        setState(() => methods.removeWhere((item) => item.id == method.id));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결제 수단을 보관하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('결제 수단 관리')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: saving ? null : add,
      icon: const Icon(Icons.add),
      label: const Text('등록'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          '결제 수단',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text('카드 실적과 거래 입력에 사용할 수단을 등록해요.'),
        const SizedBox(height: 20),
        if (methods.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('등록된 결제 수단이 없어요.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: saving ? null : add,
                    icon: const Icon(Icons.add),
                    label: const Text('첫 수단 등록'),
                  ),
                ],
              ),
            ),
          )
        else
          ...methods.map(
            (method) => Card(
              child: ListTile(
                leading: Icon(_iconFor(method.kind)),
                title: Text(method.name),
                subtitle: Text(
                  '${kinds[method.kind] ?? method.kind}${_ownerLabel(method)}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (_) => archive(method),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'archive', child: Text('보관')),
                  ],
                ),
              ),
            ),
          ),
        if (widget.onReturnToEntry != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: widget.onReturnToEntry,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('거래 입력으로 돌아가기'),
          ),
        ],
      ],
    ),
  );

  String _ownerLabel(PaymentMethodOption method) {
    final id = method.ownerMemberId;
    if (id == null) return '';
    final member = widget.contextData.members.where((item) => item.id == id);
    return member.isEmpty ? '' : ' · ${member.first.name} 사용';
  }

  IconData _iconFor(String kind) => switch (kind) {
    'cash' => Icons.payments_outlined,
    'bank' => Icons.account_balance_outlined,
    'debit_card' || 'credit_card' => Icons.credit_card_outlined,
    _ => Icons.wallet_outlined,
  };
}

class _PaymentMethodDraft {
  const _PaymentMethodDraft(this.kind, this.name, this.ownerMemberId);
  final String kind;
  final String name;
  final String? ownerMemberId;
}

class _PaymentMethodDialog extends StatefulWidget {
  const _PaymentMethodDialog({required this.members});
  final List<MemberOption> members;
  @override
  State<_PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<_PaymentMethodDialog> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  String kind = 'cash';
  String? owner;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('결제 수단 등록'),
    content: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: kind,
            decoration: const InputDecoration(labelText: '종류'),
            items: _PaymentMethodsScreenState.kinds.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => kind = value!),
          ),
          TextFormField(
            controller: name,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(labelText: '이름 (예: 국민 체크카드)'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? '이름을 입력해 주세요.' : null,
          ),
          if (widget.members.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: owner,
              decoration: const InputDecoration(labelText: '소유자 (선택)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('선택 안 함')),
                ...widget.members.map(
                  (member) => DropdownMenuItem(
                    value: member.id,
                    child: Text(member.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => owner = value),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(
              context,
              _PaymentMethodDraft(kind, name.text.trim(), owner),
            );
          }
        },
        child: const Text('등록'),
      ),
    ],
  );
}
