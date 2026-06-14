class UserModel {
  final int    id;
  final String fullName;
  final String email;
  final String role;
  final String? clinicName;
  final String? phone;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.clinicName,
    this.phone,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:          j['id']          as int,
    fullName:    j['full_name']   as String,
    email:       j['email']       as String,
    role:        j['role']        as String,
    clinicName:  j['clinic_name'] as String?,
    phone:       j['phone']       as String?,
    avatarUrl:   j['avatar_url']  as String?,
  );

  Map<String, dynamic> toJson() => {
    'id':          id,
    'full_name':   fullName,
    'email':       email,
    'role':        role,
    'clinic_name': clinicName,
    'phone':       phone,
    'avatar_url':  avatarUrl,
  };
}
