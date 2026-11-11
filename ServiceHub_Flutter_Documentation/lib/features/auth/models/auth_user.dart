enum UserRole {
  customer('CUSTOMER', 'Customer'),
  provider('PROVIDER', 'Service provider'),
  supplier('SUPPLIER', 'Supplier'),
  admin('ADMIN', 'Administrator');

  const UserRole(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static const mobileRoles = <UserRole>[
    UserRole.customer,
    UserRole.provider,
    UserRole.supplier,
  ];

  bool get canUseMobile => this != UserRole.admin;

  String get description => switch (this) {
    UserRole.customer => 'Book services, order products, and join workshops.',
    UserRole.provider =>
      'Offer services, manage inventory, and host workshops.',
    UserRole.supplier => 'List products and fulfill customer orders.',
    UserRole.admin => 'Web backoffice only.',
  };

  static UserRole parse(String raw) {
    for (final role in UserRole.values) {
      if (role.apiValue == raw) return role;
    }
    throw const FormatException('Unknown role');
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.profileImageUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? phone;
  final String? profileImageUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final fullName = json['fullName'];
    final email = json['email'];
    final role = json['role'];
    if (id == null ||
        id.toString().isEmpty ||
        fullName is! String ||
        email is! String ||
        role is! String) {
      throw const FormatException('Incomplete user');
    }
    return AuthUser(
      id: id.toString(),
      fullName: fullName,
      email: email,
      role: UserRole.parse(role),
      phone: _optionalString(json['phone']),
      profileImageUrl: _optionalString(json['profileImageUrl']),
    );
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    throw const FormatException('Unexpected user field');
  }

  @override
  bool operator ==(Object other) {
    return other is AuthUser &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.role == role &&
        other.phone == phone &&
        other.profileImageUrl == profileImageUrl;
  }

  @override
  int get hashCode =>
      Object.hash(id, fullName, email, role, phone, profileImageUrl);
}
