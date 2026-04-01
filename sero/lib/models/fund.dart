class FundTransaction {
  final String id;
  final String title;
  final String description;
  final double amount; // positive = credit, negative = debit
  final DateTime date;

  FundTransaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
  });

  bool get isCredit => amount > 0;

  factory FundTransaction.fromMap(Map<String, dynamic> map) {
    return FundTransaction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }
}

class FundSummary {
  final double totalCollected;
  final double totalSpent;

  FundSummary({required this.totalCollected, required this.totalSpent});

  double get remaining => totalCollected - totalSpent;
  double get percentRemaining =>
      totalCollected > 0 ? remaining / totalCollected : 0;
}
