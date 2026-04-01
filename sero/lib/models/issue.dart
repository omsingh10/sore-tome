class Issue {
  final String id;
  final String title;
  final String description;
  final String postedBy;
  final DateTime createdAt;
  final String status; // 'open', 'in_progress', 'resolved'

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.postedBy,
    required this.createdAt,
    this.status = 'open',
  });

  factory Issue.fromMap(Map<String, dynamic> map) {
    return Issue(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      postedBy: map['postedBy'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'postedBy': postedBy,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
