class UserModel {
  final String id;
  final String name;
  final String phone;
  final String flatNumber;
  final String block;
  final String societyName;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.flatNumber,
    required this.block,
    required this.societyName,
    this.isAdmin = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      flatNumber: map['flatNumber'] ?? '',
      block: map['block'] ?? '',
      societyName: map['societyName'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'flatNumber': flatNumber,
      'block': block,
      'societyName': societyName,
      'isAdmin': isAdmin,
    };
  }
}
