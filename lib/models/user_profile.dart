import 'package:hive/hive.dart';

part 'user_profile.g.dart';

/// User profile stored locally
/// Contains demographic info and consent status
@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String name;

  @HiveField(2)
  int? age;

  @HiveField(3)
  String? gender;

  @HiveField(4)
  bool hasConsented;

  @HiveField(5)
  DateTime? consentTimestamp;

  @HiveField(6)
  DateTime createdAt;

  UserProfile({
    required this.userId,
    required this.name,
    this.age,
    this.gender,
    required this.hasConsented,
    this.consentTimestamp,
    required this.createdAt,
  });

  factory UserProfile.create({required String name, int? age, String? gender}) {
    return UserProfile(
      userId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      age: age,
      gender: gender,
      hasConsented: false,
      createdAt: DateTime.now(),
    );
  }

  void giveConsent() {
    hasConsented = true;
    consentTimestamp = DateTime.now();
  }
}
