import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:progettomobileflutter/model/Recensione.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart';
class RecensioneViewModel with ChangeNotifier {
//TODO RIVEDERE IL NOME DEL CAMPO ID DELLA TRACCIA
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  List<Recensione> recensioniList = [];
//vedere se mettere artists
  Future<void> saveRecensione(String? userId, String trackId, String commentContent, String artistId) async {
    print('saveRecensione chiamata');
    // Genera un identificativo univoco per Firebase
    final commentId = FirebaseDatabase.instance.ref().push().key!;


    // Ottieni la data e l'ora attuali e formattale
    final currentTimestamp = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentTimestamp);

    // Crea l'oggetto recensione
    final recensione = Recensione(
      commentId: commentId,
      userId: userId ?? '',
      trackId: trackId,
      timestamp: formattedDateTime,
      content: commentContent,
      artistId: artistId,
    );

    // Salva la recensione nel database
    await FirebaseDatabase.instance.ref('reviews/$commentId').set(recensione.toMap())
        .then((value) {

      addCommentIdToTrack(commentId, trackId);
      addCommentIdToUser(commentId, userId??'');
      print("Recensione salvata con successo.");

    })
        .catchError((error) {
      // Gestisci qui l'errore
    });

    // Nascondi l'EditText o il widget di input qui
  }

  void addCommentIdToTrack(String commentId, String trackId) {
    final DatabaseReference database = FirebaseDatabase.instance.ref();
    database.child("tracks").child(trackId).child("comments").push().set(commentId);
  }

  void addCommentIdToUser(String commentId,String userId) {
    final DatabaseReference database = FirebaseDatabase.instance.ref();
    database.child("users").child(userId).child("comments").push().set(commentId);
  }



  void fetchRecensioniForTrack(String trackId, Function() onCompleted) {
    final DatabaseReference database = FirebaseDatabase.instance.ref();
    database.child("reviews").orderByChild("trackId").equalTo(trackId).onValue.listen((event) {
      recensioniList.clear();
      final DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.exists) {
        dataSnapshot.children.forEach((child) {
          final recensione = Recensione.fromMap(child.value as Map<dynamic, dynamic>);
          recensioniList.add(recensione);
        });
      }
      onCompleted(); // Chiama il callback dopo aver caricato le recensioni
    });
  }
  void fetchRecensioniForArtist(String artistId,Function() onCompleted){
    final DatabaseReference database = FirebaseDatabase.instance.ref();

    database.child("reviews")
        .orderByChild("artistId")
        .equalTo(artistId)
        .onValue.listen((event) {
      recensioniList.clear();
      final DataSnapshot dataSnapshot = event.snapshot;
      if(dataSnapshot.exists)  {
        dataSnapshot.children.forEach((child) {
          final recensione = Recensione.fromMap(child.value as Map<dynamic, dynamic>);
          print("non funziona mai nella vita $recensione");
          recensioniList.add(recensione);
          print("non funziona mai nella vita $recensioniList");
        });
      }

            onCompleted();
      });
  }

  Future<Recensione?> hasUserReviewed(String trackId, String userId) async {
    final databaseReference = FirebaseDatabase.instance.reference();

    DataSnapshot dataSnapshot = (await databaseReference.child("reviews")
        .orderByChild("trackId")
        .equalTo(trackId)
        .once()) as DataSnapshot;
    for (var snapshot in dataSnapshot.children) {
      // Controlla se `snapshot.value` è non-null e quindi prova a fare il casting a mappa
      if (snapshot.value != null) {
        final Map<String, dynamic> valueMap = Map<String, dynamic>.from(snapshot.value as Map);
        final review = Recensione.fromMap(valueMap);
        if (review.userId == userId) {
          // Se l'ID dell'utente corrisponde, restituisci la recensione trovata
          return review;
        }
      }
    }
    //else
    return null;
  }

  void deleteRecensione(String commentId) {
    final database = FirebaseDatabase.instance.ref();
    final reviewRef = database.child('reviews');
    reviewRef.child(commentId).remove();
  }



/*DA USARE POI
void checkUserReview() async {
  Recensione? review = await hasUserReviewed('trackIdQui', 'userIdQui');
  if (review != null) {
    print("L'utente ha già recensito questo brano.");
    // Gestisci la recensione trovata come necessario
  } else {
    print("Nessuna recensione trovata per l'utente su questo brano.");
    // L'utente può procedere a lasciare una recensione
  }
}

 */






}








