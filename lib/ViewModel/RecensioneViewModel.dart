import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:progettomobileflutter/model/Recensione.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart';

import '../model/Utente.dart';

class RecensioneViewModel with ChangeNotifier {
//TODO RIVEDERE IL NOME DEL CAMPO ID DELLA TRACCIA
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  List<Recensione> recensioniList = [];
  Set<String> userIds = Set();
  late Artist artist;

  Future<void> saveRecensione(String? userId, String trackId,
      String commentContent, String artistId) async {
    print('saveRecensione chiamata');
    // Genera un identificativo univoco per Firebase
    final commentId = FirebaseDatabase.instance
        .ref()
        .push()
        .key!;
    // Ottieni la data e l'ora attuali e formattale
    final currentTimestamp = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(
        currentTimestamp);

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
    await FirebaseDatabase.instance.ref('reviews/$commentId').set(
        recensione.toMap())
        .then((value) {
      addCommentIdToTrack(commentId, trackId);
      addCommentIdToUser(commentId, userId ?? '');
      updateReviewsCounter(userId, true);
      print("Recensione salvata con successo.");
    })
        .catchError((error) {

    });


  }

  Future<void> updateReviewsCounter(String? userId, bool increment) async {
    final DatabaseReference userRef = _database.ref('users/$userId');

    print('Aggiornamento del contatore recensioni per l\'utente: $userId');

    // Ottieni il valore corrente del contatore delle recensioni
    final snapshot = await userRef.child('reviews counter').get();
    int currentCount = snapshot.exists ? int.parse(snapshot.value.toString()) : 0;

    print('Valore attuale del contatore recensioni: $currentCount');

    // Aggiorna il contatore in base all'azione (incremento o decremento)
    if (increment) {
      currentCount++;
      print('Incremento del contatore recensioni.');
    } else {
      currentCount = currentCount > 0 ? currentCount - 1 : 0;
      print('Decremento del contatore recensioni. Nuovo valore: $currentCount');
    }


    await userRef.child('reviews counter').set(currentCount);
    print('Il contatore recensioni è stato aggiornato a: $currentCount');
  }




  void addCommentIdToTrack(String commentId, String trackId) {
    final DatabaseReference database = FirebaseDatabase.instance.ref();
    database.child("tracks").child(trackId).child("reviews").push().set(
        commentId);
  }

  void addCommentIdToUser(String commentId, String userId) {
    final DatabaseReference database = FirebaseDatabase.instance.ref();
    database.child("users").child(userId).child("reviews").push().set(
        commentId);
  }
  Future<void> updateRecensione(String commentId, String userId, String trackId, String commentContent, String artistId) async {
    print('updateRecensione chiamata');

    // Ottieni la data e l'ora attuali e formattale
    final currentTimestamp = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentTimestamp);

    // Crea l'oggetto recensione aggiornato
    final updatedRecensione = Recensione(
      commentId: commentId,
      userId: userId,
      trackId: trackId,
      timestamp: formattedDateTime,
      content: commentContent,
      artistId: artistId,
    );

    // Aggiorna la recensione nel database
    await FirebaseDatabase.instance.ref('reviews/$commentId').update(updatedRecensione.toMap())
        .then((value) {
      print("Recensione aggiornata con successo.");
    }).catchError((error) {
      // Gestisci qui l'errore
      print("Errore nell'aggiornamento della recensione: $error");
    });
  }


  void fetchTracksReviewedByArtistAndRetrieveDetails(String artistId,
      Function(List<Track>) onComplete) {
    fetchTracksReviewedByArtist(artistId, (List<String> trackIds) {
      if (trackIds.isNotEmpty) {
        retrieveTracksDetails(trackIds, (List<Track> tracks) {
          onComplete(tracks); // Callback con i dettagli delle tracce
        });
      } else {
        onComplete(
            []); // Callback con una lista vuota se non ci sono tracce recensite
      }
    });
  }


  void fetchTracksReviewedByArtist(String artistId,
      Function(List<String> trackIds) onComplete) {
    List<String> tracksReviewedIds = [];
    final DatabaseReference database = FirebaseDatabase.instance.ref();
    database
        .child("reviews")
        .orderByChild("artistId")
        .equalTo(artistId)
        .onValue
        .listen((event) {
      tracksReviewedIds
          .clear(); // Pulisce la lista prima di riempirla con nuovi ID
      final DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.exists) {
        dataSnapshot.children.forEach((child) {
          final recensione = Recensione.fromMap(
              child.value as Map<dynamic, dynamic>);
          String trackId = recensione
              .trackId;
          if (!tracksReviewedIds.contains(trackId)) {
            tracksReviewedIds.add(trackId);
          }
        });
        onComplete(
            tracksReviewedIds); // Richiama il callback passando gli ID delle tracce recensite
      } else {
        onComplete(
            []); // Richiama il callback con una lista vuota se non ci sono dati
      }
    });
  }

  Future<Artist?> retrieveArtistById(String artistId) async {
    final database = FirebaseDatabase.instance.ref();
    final artistRef = database.child('artists').child(artistId);

    DatabaseEvent event = await artistRef.once();

    if (event.snapshot.exists) {
      // Converte il dataSnapshot in un Map<String, dynamic>
      Map<String, dynamic> artistData = Map<String, dynamic>.from(event.snapshot.value as Map);
      artistData['id'] = artistId; // Assicurati che l'ID sia incluso nei dati, se necessario
      return Artist.fromJson(artistData);
    }
    return null;
  }


  void retrieveTracksDetails(List<String> trackIds,
      Function(List<Track>)? onComplete) async {
    print("retrieve chiamata");
    print(
        "Inizio di retrieveTracksDetails con ${trackIds.length} ID di tracce");
    final database = FirebaseDatabase.instance.ref();
    final tracksRef = database.child('tracks');
    final artistsRef = database.child('artists');
    List<Track> tracks = [];

    List<Future<Track>> trackFutures = trackIds.map((trackId) async {
      print("Recupero dettagli per la traccia $trackId");
      final trackSnapshot = await tracksRef.child(trackId).get();
      print("Snapshot per traccia $trackId recuperato");

      Map<String, dynamic> trackData;
      try {
        trackData =
            (trackSnapshot.value as Map?)?.cast<String, dynamic>() ?? {};
      } catch (_) {
        print(
            "Il valore recuperato per la traccia $trackId non è una mappa valida, utilizzando valori predefiniti.");
        trackData = {};
      }

      List<Future<Artist>> artistFutures = [];
      if (trackData['artists'] != null) {
        artistFutures = (trackData['artists'] as List).map((artistId) async {
          final artistSnapshot = await artistsRef.child(artistId).get();
          final artistData = (artistSnapshot.value as Map?)?.cast<
              String,
              dynamic>() ?? {};
          return Artist.fromJson(artistData);
        }).toList();
      }

      List<Artist> artists = await Future.wait(artistFutures);
      print("Artisti per la traccia $trackId recuperati: ${artists.length}");

      Track track;
      try {
        track = Track.fromJson({
          'name': trackData['name'],
          'album': {
            'name': trackData['album'],
            'images': [{'url': trackData['image_url'] ?? 'immagine mancante'}],
            'release_date': trackData['release_date'] ??
                'release date mancante',
          },
          'artists': artists.map((artist) => artist.toJson()).toList(),
          'id': trackId,
        });
        print("ultima prova ${track.album.images[0].url}");
        print("ultima prova ${track.name}");
      } catch (e) {
        print('Errore durante la deserializzazione della traccia $trackId: $e');
        rethrow;
      }
      return track;
    }).toList();


    tracks = await Future.wait(trackFutures);
    print("Tutte le tracce sono state recuperate: ${tracks.length}");

    onComplete?.call(tracks);
  }


  void fetchRecensioniForTrack(String trackId, Function() onCompleted,) {
    final DatabaseReference database = FirebaseDatabase.instance.ref();
    database
        .child("reviews")
        .orderByChild("trackId")
        .equalTo(trackId)
        .onValue
        .listen((event) {
      recensioniList.clear();
      final DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.exists) {
        dataSnapshot.children.forEach((child) {
          final recensione = Recensione.fromMap(
              child.value as Map<dynamic, dynamic>);
          recensioniList.add(recensione);
          userIds.add(recensione.userId);
        });
      }
      fetchUsers(userIds.toList()).then((Map<String, Utente> usersMap) {

        print("SIAMO QUI");
        print(
            "Dettagli utenti recuperati. Numero di utenti: ${usersMap.length}");
        usersMap.forEach((userId, utente) {
          print("DAJE ROMA UserID: $userId, Nome: ${utente.name},IMAGE: ${utente
              .profile_image}  Email: ${utente.email}");
        });
      });
      onCompleted(); // Chiama il callback dopo aver caricato le recensioni
    });
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
          DatabaseEvent imageEvent = await database.child(
              "users/$userId/profile image").once();
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

  void fetchRecensioniForArtist(String artistId, Function() onCompleted) {
    final DatabaseReference database = FirebaseDatabase.instance.ref();

    database
        .child("reviews")
        .orderByChild("artistId")
        .equalTo(artistId)
        .onValue
        .listen((event) {
      recensioniList.clear();
      final DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.exists) {
        dataSnapshot.children.forEach((child) {
          final recensione = Recensione.fromMap(
              child.value as Map<dynamic, dynamic>);
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
        final Map<String, dynamic> valueMap = Map<String, dynamic>.from(
            snapshot.value as Map);
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
  Future<void> deleteRecensioneFromUser(String commentId, String userId) async {
    final DatabaseReference database = FirebaseDatabase.instance.ref();
    final DatabaseReference userReviewsRef = database.child("users").child(userId).child("reviews");

    // Ottieni tutte le recensioni dell'utente
    final snapshot = await userReviewsRef.get();

    // Cerca attraverso le recensioni per trovare l'ID della recensione da rimuovere
    for (final child in snapshot.children) {
      if (child.value == commentId) {
        // Quando trovi una corrispondenza, rimuovi quella recensione specifica
        await child.ref.remove();
        await updateReviewsCounter(userId, false);
        break; // Interrompi il ciclo se hai trovato e rimosso l'ID della recensione
      }
    }


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








