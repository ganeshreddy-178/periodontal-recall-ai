class PatientModel {
  final int    id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String dateOfBirth;
  final int    age;
  final String gender;
  final String? phone;
  final String? email;
  final String smokingStatus;
  final String diabetesStatus;
  final bool   familyHistory;
  final bool   previousPeriodontal;
  final String? notes;
  final String createdAt;

  const PatientModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.dateOfBirth,
    required this.age,
    required this.gender,
    required this.smokingStatus,
    required this.diabetesStatus,
    required this.familyHistory,
    required this.previousPeriodontal,
    required this.createdAt,
    this.phone,
    this.email,
    this.notes,
  });

  factory PatientModel.fromJson(Map<String, dynamic> j) => PatientModel(
    id:                  j['id']                     as int,
    firstName:           j['first_name']              as String,
    lastName:            j['last_name']               as String,
    fullName:            j['full_name']               as String,
    dateOfBirth:         j['date_of_birth']           as String,
    age:                 j['age']                     as int,
    gender:              j['gender']                  as String,
    phone:               j['phone']                   as String?,
    email:               j['email']                   as String?,
    smokingStatus:       j['smoking_status']          as String,
    diabetesStatus:      j['diabetes_status']         as String,
    familyHistory:       (j['family_history']  == true || j['family_history']  == 1),
    previousPeriodontal: (j['previous_periodontal'] == true || j['previous_periodontal'] == 1),
    notes:               j['notes']                   as String?,
    createdAt:           j['created_at']              as String,
  );
}
