import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart';



class FirebaseViewModel {

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Metodo per ottenere gli ID utente
  Future<List<String>> getUserIds() async {
    DatabaseReference databaseReference =
    FirebaseDatabase.instance.reference().child('users');

    DataSnapshot dataSnapshot = (await databaseReference.once()).snapshot;

    if (dataSnapshot.value != null && dataSnapshot.value is Map) {
      Map<dynamic, dynamic> userData = dataSnapshot.value as Map<dynamic, dynamic>;
      return userData.keys.cast<String>().toList();
    } else {
      return [];
    }
  }

  // Metodo per ottenere i nomi degli utenti
  Future<Map<String, String>> getUserNames(List<String> userIds) async {
    Map<String, String> userNames = {};

    for (String userId in userIds) {
      DatabaseReference userReference =
      FirebaseDatabase.instance.reference().child('users').child(userId);

      DataSnapshot userSnapshot = (await userReference.once()).snapshot;

      if (userSnapshot.value != null) {
        Map<dynamic, dynamic> userData =
        userSnapshot.value as Map<dynamic, dynamic>;
        String userName = userData['name'];
        userNames[userId] = userName;
      }
    }

    return userNames;
  }

  Future<void> saveTracksToMainNode(List<Track> tracks) async {
    final tracksRef = _database.ref('tracks');

    for (var track in tracks) {
      //prendi l url della prima immagine altrimenti stringa vuota
      String imageUrl = track.album.images.isNotEmpty ? track.album.images[0].url : "";
      //trasformo l elenco degli artisti di una traccia in una lista di id di artisti di una traccia
      List<String> artistIdsForTrackNode = track.artists.map((artist) => artist.id).toList();

      Map<String, dynamic> trackData = {
        'trackName': track.name,
        'album': track.album.name,
        'artists': artistIdsForTrackNode,
        'id': track.id,
        'release_date': track.album.releaseDate,
        'image_url': imageUrl,
      };

      try {
        //await aspetta che l operazione dei salvataggio dei dati sia completata
        await tracksRef.child(track.id).set(trackData);
        print('Traccia ${track.id} salvata su Firebase nel nodo principale.');

        // Qui va funzione per riprendere artisti non nella top artist

      } catch (error) {
        print('Errore nel salvataggio della traccia ${track.id} su Firebase: ${error.toString()}');
      }

    }
  }

  Future<void> saveArtistsToMainNode(List<Artist> topArtists) async {
    final artistsRef = _database.ref('artists');

    for (var artist in topArtists) {
      //prene l url della prima immagine altrimenti stringa vuota
      String imageUrl = artist.images.isNotEmpty ? artist.images[0].url : "";
      Map<String, dynamic> artistData = {
        'name': artist.name,
        'genres': artist.genres,
        'id': artist.id,
        'image_url': imageUrl,
      };
      try {//await aspetta che l operazione dei salvataggio dei dati sia completata
        await artistsRef.child(artist.id).set(artistData);
        print("Artista ${artist.id} salvato su Firebase nel nodo principale.");
      } catch (error) {
        print("Errore nel salvataggio dell'artista ${artist.id} su Firebase:");
      }

    }
  }

}




