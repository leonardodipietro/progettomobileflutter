import 'package:firebase_auth/firebase_auth.dart' as auth;


class Utente {
  final String? userId;
  final String? email;
  final String? name;
  final String? profile_image;

  Utente({required this.userId, this.email, this.name, this.profile_image});

  factory Utente.fromFirebaseUser(auth.User firebaseUser) {
    return Utente(
      userId: firebaseUser.uid,
      email: firebaseUser.email,
      name: firebaseUser.displayName,
      profile_image: firebaseUser.photoURL
    );
  }
  factory Utente.fromMap(Map<String, dynamic> map) {
    return Utente(
      userId: map['userId'],
      email: map['email'],
      name: map['name'],
      profile_image: map['profile_image'],
    );
  }



  Map<String, dynamic> toMap() {
    return {
      'userId': userId ?? '',
      'email': email ?? '',
      'name': name ?? '',
      'profile_image':profile_image?? '',
    };
  }
}
