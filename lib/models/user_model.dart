import 'dart:convert';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final int totalListeningMinutes;
  final int totalPdfsUploaded;
  final int streakDays;
  final String lastActiveDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.totalListeningMinutes = 0,
    this.totalPdfsUploaded = 0,
    this.streakDays = 0,
    this.lastActiveDate = '',
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    int? totalListeningMinutes,
    int? totalPdfsUploaded,
    int? streakDays,
    String? lastActiveDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      totalListeningMinutes: totalListeningMinutes ?? this.totalListeningMinutes,
      totalPdfsUploaded: totalPdfsUploaded ?? this.totalPdfsUploaded,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'totalListeningMinutes': totalListeningMinutes,
      'totalPdfsUploaded': totalPdfsUploaded,
      'streakDays': streakDays,
      'lastActiveDate': lastActiveDate,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Student',
      photoUrl: map['photoUrl'] ?? '',
      totalListeningMinutes: map['totalListeningMinutes'] ?? 0,
      totalPdfsUploaded: map['totalPdfsUploaded'] ?? 0,
      streakDays: map['streakDays'] ?? 0,
      lastActiveDate: map['lastActiveDate'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source));
}
