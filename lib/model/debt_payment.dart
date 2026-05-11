class DebtPayment {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime paymentDate;
  final String? note;
  final bool isFullPayment;

  DebtPayment({
    this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    this.note,
    this.isFullPayment = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'note': note,
      'is_full_payment': isFullPayment,
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'] as int?,
      debtId: map['debt_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'].toString()),
      note: map['note'] as String?,
      isFullPayment: map['is_full_payment'] as bool? ?? false,
    );
  }

  DebtPayment copyWith({
    int? id,
    int? debtId,
    double? amount,
    DateTime? paymentDate,
    String? note,
    bool? isFullPayment,
  }) {
    return DebtPayment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      note: note ?? this.note,
      isFullPayment: isFullPayment ?? this.isFullPayment,
    );
  }
}