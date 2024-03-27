import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:progettomobileflutter/model/Risposta.dart';

import '../model/Utente.dart';

class RisposteViewModel {
  List<Risposta> risposteList = [];
  Set<String> userIds = {};


  Future<void> saveRisposta(
      String userId, String commentIdfather, String answercontent) async {
    // Generate a unique identifier for Firebase
    DatabaseReference databaseRef =
        FirebaseDatabase.instance.ref().child('answers').push();
    String answerId = databaseRef.key!;

    // Get current date and time
    final currentTimestamp = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final formattedDateTime = formatter.format(currentTimestamp);

    Risposta risposta = Risposta(
      userId: userId,
      answerId: answerId,
      commentIdfather: commentIdfather,
      timestamp: formattedDateTime,
      answercontent: answercontent,
    );

    // Save to Firebase
    await databaseRef.set(risposta.toMap()).then((_) {
      print("Comment saved on Firebase with $risposta");
    }).catchError((error) {
      print("Error saving comment: $error");
    });
  }

  /*Future<List<Risposta>> fetchCommentFromRecensione(
      String commentIdFather) async {
    final databaseRef = FirebaseDatabase.instance.ref();
    List<Risposta> commentiList = [];

    try {
      // Recupera tutti i dati dal nodo 'answers'
      DataSnapshot dataSnapshot = await databaseRef.child("answers").get();

      if (dataSnapshot.exists) {
        final dati = dataSnapshot.value as Map<dynamic, dynamic>;
        // Filtra i dati lato client
        dati.forEach((key, value) {
          final commento = Risposta.fromMap(value as Map<dynamic, dynamic>);
          if (commento.commentIdfather == commentIdFather) {
            commentiList.add(commento);
            userIds.add(commento.userId);
          }
        });
      }
      else {
        print("Nessun commento trovato.");
      }
    } catch (error) {
      print("Errore nel recuperare i commenti: $error");
    }
    fetchUsers(userIds.toList()).then((Map<String, Utente> usersMap) {

      print("SIAMO QUI");
      print(
          "Dettagli utenti recuperati. per le risposte  Numero di utenti: ${usersMap.length}");
      usersMap.forEach((userId, utente) {
        print("DAJE forse  UserID: $userId, Nome: ${utente.name},IMAGE: ${utente
            .profile_image}  Email: ${utente.email}");
      });
    });


    return commentiList;
  }*/

  Future<List<Risposta>> fetchCommentFromRecensione(String commentIdFather) async {
    final databaseRef = FirebaseDatabase.instance.ref();
    List<Risposta> commentiList = [];
    List<String> userIds = [];

    try {
      DataSnapshot dataSnapshot = await databaseRef.child("answers").get();
      if (dataSnapshot.exists) {
        final dati = dataSnapshot.value as Map<dynamic, dynamic>;
        dati.forEach((key, value) {
          final commento = Risposta.fromMap(value as Map<dynamic, dynamic>);
          if (commento.commentIdfather == commentIdFather) {
            commentiList.add(commento);
            userIds.add(commento.userId); // Raccogli gli ID utente qui
          }
        });
      } else {
        print("Nessun commento trovato.");
      }
    } catch (error) {
      print("Errore nel recuperare i commenti: $error");
    }


    return commentiList;
  }



  Future<Map<String, Utente>> fetchUsers(List<String> userIds) async {
    final DatabaseReference database = FirebaseDatabase.instance.ref();
    Map<String, Utente> usersMap = {};
    for (String userId in userIds) {
      // Prende i dettagli utente base.
      DatabaseEvent userEvent = await database.child("users/$userId").once();
      if (userEvent.snapshot.exists) {
        final userMap = userEvent.snapshot.value as Map<dynamic, dynamic>?;
        if (userMap != null) {
          // Prende l'URL dell'immagine del profilo.
          String? profileImageUrl;
          DatabaseEvent imageEvent =
              await database.child("users/$userId/profile image").once();
          if (imageEvent.snapshot.exists) {
            profileImageUrl = imageEvent.snapshot.value as String?;
          }

          final utente = Utente.fromMap(Map<String, dynamic>.from(userMap)
            ..['profile_image'] = profileImageUrl);
          usersMap[userId] = utente;
        }
      }
    }
    return usersMap;
  }

  void deleteRisposta(String answerId) {
    final database = FirebaseDatabase.instance.ref();
    final reviewRef = database.child('answers');
    reviewRef.child(answerId).remove();
  }
}
