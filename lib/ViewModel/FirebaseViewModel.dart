import 'package:firebase_database/firebase_database.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart';
import 'package:progettomobileflutter/model/Utente.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';//serve per il provider

class FirebaseViewModel extends ChangeNotifier{

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  List<Track> tracksFromDb =[];
  List<Artist> artistsFromDb =[];
  // Metodo per ottenere gli ID utente
  Future<List<String>> getUserIds() async {
    DatabaseReference databaseReference =
    FirebaseDatabase.instance.ref().child('users');

    DataSnapshot dataSnapshot = (await databaseReference.once()).snapshot;

    if (dataSnapshot.value != null && dataSnapshot.value is Map) {
      Map<dynamic, dynamic> userData = dataSnapshot.value as Map<dynamic, dynamic>;
      return userData.keys.cast<String>().toList();
    } else {
      return [];
    }
  }


  Future<bool> checkUserIdInFirebase(String userId) async {
    final DatabaseReference userRef = _database.ref().child('users').child(userId);
    DatabaseEvent event = await userRef.once();
    return event.snapshot.value != null;
  }


  Future<void> saveUserIdToFirebase(String userId) async {
    final DatabaseReference userRef = _database.ref().child('users').child(userId);
    final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("Errore: Nessun utente corrente trovato.");
      return;
    }

    final Map<String, dynamic> userData = {
      'name': currentUser.displayName ?? '',
      'email': currentUser.email ?? '',
      'userId': userId,
    };

    final bool isRegistered = await checkUserIdInFirebase(userId);
    if (!isRegistered) {
      await userRef.set(userData).then((_) {
        print("ID utente salvato su Firebase: $userData");
      }).catchError((error) {
        print("Errore nel salvataggio dell'ID utente su Firebase: ${error.toString()}");
      });
    } else {
      print("L'utente è già registrato nel database.");
    }
  }








  Future<void> saveTracksToMainNode(List<Track> tracks) async {
    final DatabaseReference tracksRef = _database.ref().child('tracks');

    for (var track in tracks) {
      String imageUrl = track.album.images.isNotEmpty ? track.album.images[0].url : "";
      List<String> artistIdsForTrackNode = track.artists.map((artist) => artist.id).toList();

      Map<String, dynamic> trackData = {
        'name': track.name,
        'album': track.album.name,
        'artists': artistIdsForTrackNode,
        'id': track.id,
        'release_date': track.album.releaseDate,
        'image_url': imageUrl,
      };

      try {
        await tracksRef.child(track.id).set(trackData);
        print('Traccia ${track.id} salvata su Firebase nel nodo principale.');
        saveArtistsFromTracks(tracks);
      } catch (error) {
        print('Errore nel salvataggio della traccia ${track.id} su Firebase: ${error.toString()}');
      }
    }
  }
  //serve per recuperare il nome degli artisti che non sono presenti nella top artists dalle top tracks
  void saveArtistsFromTracks(List<Track> tracks)
  {
    print("Artista BBBB  ");
    final artistsRef = FirebaseDatabase.instance.ref().child('artists');

    final uniqueArtists = tracks
    // Estraiamo tutti gli artisti unici dai brani e li mettiamo in una lista a parte
        .expand((track) => track.artists)
        .toSet() //converte la lista in un set di dati per eliminare i duplicati
        .toList();

    for (final artist in uniqueArtists) {
      final artistId = artist.id;
      artistsRef.child(artistId).get().then((dataSnapshot) {
        if (!dataSnapshot.exists) {
          final imageUrl = artist.images.isNotEmpty ? artist.images.first.url : '';
          print("Artista BBBB  ");
          final artistData = {
            'name': artist.name,
            'genres': artist.genres,
            'id': artist.id,
            'image_url': imageUrl,
          };

          artistsRef.child(artistId).set(artistData).then((_) {
            print("Artista BBBB $artistId salvato su Firebase nel nodo artists.");
          }).catchError((error) {
            debugPrint("Errore nel salvataggio dell'artista $artistId su Firebase: ${error.message}");
          });
        }
      }).catchError((error) {
        // Gestisci gli errori qui
        debugPrint("Errore durante il recupero dell'artista $artistId: ${error.message}");
      });
    }
    print("ciao");
  }


  Future<void> saveArtistsToMainNode(List<Artist> topArtists) async {
    final DatabaseReference artistsRef = _database.ref().child('artists');

    for (var artist in topArtists) {
      String imageUrl = artist.images.isNotEmpty ? artist.images[0].url : "";
      Map<String, dynamic> artistData = {
        'name': artist.name,
        'genres': artist.genres,
        'id': artist.id,
        'image_url': imageUrl,
      };

      try {
        await artistsRef.child(artist.id).set(artistData);
        print("Artista ${artist.id} salvato su Firebase nel nodo principale.");
      } catch (error) {
        print("Errore nel salvataggio dell'artista ${artist.id} su Firebase: ${error.toString()}");
      }
    }
  }

  Future<void> saveUserTopTracks(String userId, List<Track> topTracks, String timeRange) async {
    final DatabaseReference userTopTracksRef = _database.ref()
        .child('user').child(userId).child('topTracks').child(timeRange);

    final List<String> trackIds = topTracks.map((track) => track.id).toList();

    try {
      await userTopTracksRef.set(trackIds);
      print("IDs delle tracce salvate per l'utente $userId.");
    } catch (error) {
      print("Errore nel salvataggio degli IDs delle tracce per l'utente $userId: ${error.toString()}");
    }
  }

  Future<void> saveUserTopArtists(String userId, List<Artist> topArtists, String timeRange) async {
    final DatabaseReference userTopArtistsRef = _database.ref()
        .child('users').child(userId).child('topArtists').child(timeRange);

    final List<String> artistIds = topArtists.map((artist) => artist.id).toList();

    try {
      await userTopArtistsRef.set(artistIds);
      print("IDs delle tracce salvate per l'utente $userId.");
    } catch (error) {
      print("Errore nel salvataggio degli IDs delle tracce per l'utente $userId: ${error.toString()}");
    }
  }
  Future<void> fetchTopArtistsFromFirebase(String filter) async {
    final userId = auth.FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userTopArtistsRef = FirebaseDatabase.instance.ref('user/$userId/topArtists/$filter');
      try {
        print("Tentativo di recupero tracce per l'utente $userId con filtro $filter");
        DatabaseEvent event = await userTopArtistsRef.once();
        print("DatabaseEvent recuperato con successo");
        // Assumendo che i valori siano gli ID delle tracce e possano essere trattati come String
        final artistIds = event.snapshot.children.map((child) => child.value.toString()).toList();
        retrieveArtistsDetails(artistIds,(List<Artist> artists) {
          for(var artist in artists)
          {
            print("Artist ricacciati: ${artist.name} e ${artist.images[0].url}");
            artistsFromDb=artists;
          }
        });


      } catch (error) {
        print('FirebaseError: Error while fetching track IDs from Firebase database: $error');
      }
    }
  }

  void retrieveArtistsDetails(List<String> artistIds, Function(List<Artist>) onComplete) async {
    final artistsRef = FirebaseDatabase.instance.ref('artists');
    List<Artist> artists = [];

    List<Future<void>>

    artistFutures = artistIds.map((artistId) async {
      final artistSnapshot = await artistsRef.child(artistId).get();

      if (artistSnapshot.exists) {
        // Evitiamo il cast diretto utilizzando dynamic e accedendo ai valori con un approccio più sicuro
        var artistData = artistSnapshot.value as dynamic;

        String imageUrl = '';
        if (artistData['image_url'] != null) {
          imageUrl = artistData['image_url'] as String;
        }


        Artist artist = Artist.fromJson({
          'name': artistData['name'],
          'id': artistId,
          'genres': artistData['genres'] ?? [],
          'images': imageUrl.isNotEmpty ? [{'url': imageUrl}] : [], // Corretto
        });

        artists.add(artist);
      }
    }).toList();

    // Attendi il completamento di tutte le future
    await Future.wait(artistFutures);

    // Esegui la callback con la lista di artisti recuperata
    onComplete(artists);
  }

  /*void retrieveArtistsDetails(List<String> artistIds, Function(List<Artist>) onComplete) async {
    final artistsRef = FirebaseDatabase.instance.ref('artists');
    List<Artist> artists = [];

    List<Future<void>> artistFutures = artistIds.map((artistId) async {
      final artistSnapshot = await artistsRef.child(artistId).get();

      if (artistSnapshot.exists) {
        // Evitiamo il cast diretto utilizzando dynamic e accedendo ai valori con un approccio più sicuro
        var artistData = artistSnapshot.value as dynamic;

        /*// Estrazione sicura dell'URL dell'immagine
        String imageUrl = '';
        if (artistData['images'] != null && artistData['images'] is List && artistData['images'].isNotEmpty) {
          var firstImage = artistData['images'][0];
          if (firstImage is Map && firstImage.containsKey('url')) {
            imageUrl = firstImage['url'] as String;
          }
        }*/

        // Creiamo un'istanza di Artist usando i dati recuperati con un approccio che evita il cast diretto
        Artist artist = Artist.fromJson({
          'name': artistData['name'],
          'id': artistId,
          'genres': artistData['genres'] ?? [],
          'images': [{'url': artistData['image_url'] ?? 'immagine mancante'}],
        });

        artists.add(artist);
      }
    }).toList();

    // Attendi il completamento di tutte le future
    await Future.wait(artistFutures);

    // Esegui la callback con la lista di artisti recuperata
    onComplete(artists);
  }
*/

  Future<void> fetchTopTracksFromFirebase(String filter) async {
    final userId = auth.FirebaseAuth.instance.currentUser?.uid;
    print("DDDD ${userId}");
    if (userId != null) {
      final userTopTracksRef = FirebaseDatabase.instance.ref('user/$userId/topTracks/$filter');
      try {
        print("Tentativo di recupero tracce per l'utente $userId con filtro $filter");
        DatabaseEvent event = await userTopTracksRef.once();
        print("DatabaseEvent recuperato con successo");
        // Assumendo che i valori siano gli ID delle tracce e possano essere trattati come String
        //map prence i child e ne recupera il value che poi viene convertito in una stringa e poi inserito in una lista
        final trackIds = event.snapshot.children.map((child) => child.value.toString()).toList();
        print("prechiamata ${trackIds}");
        // Ora passiamo una funzione di callback a retrieveTracksDetails
        retrieveTracksDetails(trackIds, (List<Track> tracks) {
          print("Numero di tracce recuperate: ${trackIds.length}");
          // Qui puoi stampare i dettagli delle tracce come desideri
          for (var track in tracks) {
            for (var artist in track.artists) {
              print("Artist: ${artist.name}");
        print("ROBA RICACCIATA Track: ${track.name}, Album: ${track.album.name}, IMMAGINE ${track.album.images[0].url}. Artist${artist.name}");
        tracksFromDb=tracks;
            }

          }
        }


        );
      } catch (error) {
        print('FirebaseError: Error while fetching track IDs from Firebase database: $error');
      }
    }
  }

  void retrieveTracksDetails(List<String> trackIds, Function(List<Track>)? onComplete) async {
    print("retrieve chiamata");
    print("Inizio di retrieveTracksDetails con ${trackIds.length} ID di tracce");
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
        trackData = (trackSnapshot.value as Map?)?.cast<String, dynamic>() ?? {};
      } catch (_) {
        print("Il valore recuperato per la traccia $trackId non è una mappa valida, utilizzando valori predefiniti.");
        trackData = {};
      }

      List<Future<Artist>> artistFutures = [];
      if (trackData['artists'] != null) {
        artistFutures = (trackData['artists'] as List).map((artistId) async {
          final artistSnapshot = await artistsRef.child(artistId).get();
          final artistData = (artistSnapshot.value as Map?)?.cast<String, dynamic>() ?? {};
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
            'release_date': trackData['release_date'] ?? 'release date mancante',
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

}





