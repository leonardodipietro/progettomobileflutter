import 'package:firebase_auth/firebase_auth.dart' as auth;


class Utente {
  final String userId;
  final String? email;
  final String? name;

  Utente({required this.userId, this.email, this.name});

  factory Utente.fromFirebaseUser(auth.User firebaseUser) {
    return Utente(
      userId: firebaseUser.uid,
      email: firebaseUser.email,
      name: firebaseUser.displayName,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email ?? '',
      'name': name ?? '',
    };
  }
}
