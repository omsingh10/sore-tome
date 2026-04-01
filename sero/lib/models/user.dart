class UserModel {
  final String id;
  final String name;
  final String phone;
  final String flatNumber;
  final String block;
  final String role;
  final String status;
  final String residentType;
  final bool maintenanceExempt;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.flatNumber,
    required this.block,
    required this.role,
    required this.status,
    this.residentType = 'owner',
    this.maintenanceExempt = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['uid'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      flatNumber: map['flatNumber'] ?? '',
      block: map['blockName'] ?? map['block'] ?? '',
      role: map['role'] ?? 'resident',
      status: map['status'] ?? 'pending',
      residentType: map['residentType'] ?? 'owner',
      maintenanceExempt: map['maintenanceExempt'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'phone': phone,
      'flatNumber': flatNumber,
      'blockName': block,
      'role': role,
      'status': status,
      'residentType': residentType,
      'maintenanceExempt': maintenanceExempt,
    };
  }
}
