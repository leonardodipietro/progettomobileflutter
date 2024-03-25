import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:progettomobileflutter/BranoSelezionato.dart';
import 'package:progettomobileflutter/pagina_amico.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart';

enum TipoNotifica {
  nuovoFollower,
  nuovaRecensione,
}

class Notifica {
  final TipoNotifica tipo;
  final String? reviewId;
  final String mittente;
  final String userId;
  final String testo;
  final String? immagineProfilo;
  final IconData immagineDefault;// Icona di default nel caso in cui non ci sia un'immagine profilo
  bool isFollowing; // Indica se l'utente corrente sta già seguendo il mittente della notifica
  final DateTime? timestamp;
  final String? trackId;

  Notifica({
    required this.tipo,
    this.reviewId,
    required this.mittente,
    required this.userId,
    required this.testo,
    required this.immagineProfilo,
    required this.immagineDefault,
    required this.isFollowing,
    this.timestamp,
    this.trackId
  });
}

class NotifichePage extends StatefulWidget {
  const NotifichePage({super.key});

  @override
  NotifichePageState createState() => NotifichePageState();
}

class NotifichePageState extends State<NotifichePage> {
  late User currentUser;
  List<Notifica> notifiche = [];

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUser = user;
      startFollowerListener();
      startFollowingListener();
      startReviewListener();
    }
  }

  void addNewFollowerNotification(String followerId, bool isFollowing) {
    setState(() {
      notifiche.add(
        Notifica(
          tipo: TipoNotifica.nuovoFollower,
          mittente: "Nuovo Follower",
          testo: "Ha iniziato a seguirti.",
          userId: followerId,
          immagineProfilo: null,
          immagineDefault: Icons.account_circle,
          isFollowing: isFollowing,
        ),
      );
    });
  }

  void checkNewFollower(String followerId) {
    // Query per controllare se il followerId è un nuovo follower
    bool isNewFollower = true;
    if (isNewFollower) {
      // Se followerId è un nuovo follower, aggiunge la notifica
      checkFollowingStatus(followerId);
      print(
          'Nuovo utente: $followerId');
      // Controlla se il nuovo follower è tra i following dell'utente corrente
      checkFollowingStatus(followerId);
    }
  }

  Future<void> checkFollowingStatus(String followerId) async {
    // Controlla se l'ID del follower è presente tra i following dell'utente corrente
    DataSnapshot snapshot = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUser.uid)
        .child('following')
        .child(followerId)
        .once().then((event) => event.snapshot);
    bool isFollowing = snapshot.exists;

    // Aggiunge la notifica dopo aver ottenuto lo stato di isFollowing
    addNewFollowerNotification(followerId, isFollowing);
    if (isFollowing) {
      print('Il follower $followerId è già tra i tuoi following');
      getReviewData(followerId);
    } else {
      print('Il follower $followerId non è tra i tuoi following');
    }
  }

  void startFollowerListener() {
    FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUser.uid)
        .child('followers')
        .onChildAdded
        .listen((event) {
      String followerId = event.snapshot.key ?? ""; // Ottiene l'ID del nuovo follower
      // Ottiene le informazioni del follower in modo asincrono
      getFollowerData(followerId);
    });

    FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUser.uid)
        .child('followers')
        .onChildRemoved
        .listen((event) {
      String followerId = event.snapshot.key ?? ""; // Ottiene l'ID del follower rimosso
      removeFollowerNotification(followerId);
    });
  }

  void startFollowingListener() {
    FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUser.uid)
        .child('following')
        .onChildAdded
        .listen((event) {
      String followingUserId = event.snapshot.key ?? ""; // Ottiene l'ID dell'utente che sta seguendo
      // Aggiorna lo stato di isFollowing nelle notifiche
      updateFollowingStatusInNotification(followingUserId, true);
    });

    FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUser.uid)
        .child('following')
        .onChildRemoved
        .listen((event) {
      String removedUserId = event.snapshot.key ?? ""; // Ottieni l'ID dell'utente rimosso dai following
      // Rimuove le notifiche relative alle recensioni dell'utente rimosso
      removeReviewsByUserId(removedUserId);
      // Aggiorna lo stato di isFollowing nelle notifiche
      updateFollowingStatusInNotification(removedUserId, false);
    });
  }

  void updateFollowingStatusInNotification(String userId, bool isFollowing) {
    setState(() {
      for (var notification in notifiche) {
        if (notification.userId == userId) {
          notification.isFollowing = isFollowing;
        }
      }
    });
  }

  void getFollowerData(String followerId) async {
    // Ottiene le informazioni del follower
    DatabaseReference followerRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(followerId);
    DataSnapshot followerSnapshot = await followerRef.once().then((event) => event.snapshot);
    Map<dynamic, dynamic>? followerData = followerSnapshot.value as Map<dynamic, dynamic>?;

    if (followerData != null) {
      // Estrae le informazioni necessarie dal nodo del follower
      String followerName = followerData['name'] ?? '';
      String followerProfileImage = followerData['profile image'] ?? '';

      // Verifica se followerProfileImage è una stringa non vuota
      String? immagineProfilo;
      if (followerProfileImage.isNotEmpty) {
        immagineProfilo = followerProfileImage;
      }

      // Verifica se il follower è tra i following dell'utente corrente
      DataSnapshot followingSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('following')
          .child(followerId)
          .once().then((event) => event.snapshot);
      bool isFollowing = followingSnapshot.exists;

      setState(() {
          notifiche.add(
            Notifica(
              tipo: TipoNotifica.nuovoFollower,
              mittente: followerName,
              userId: followerId,
              testo: " ha iniziato a seguirti.",
              immagineProfilo: immagineProfilo,
              immagineDefault: Icons.account_circle,
              isFollowing: isFollowing,
            ),
          );
        });
    }
  }

  void removeFollowerNotification(String followerId) {
    setState(() {
      notifiche.removeWhere((notifica) => notifica.userId == followerId);
    });
  }

  void toggleFollowStatus(String followerId, int index) async {
    bool isFollowing = notifiche[index].isFollowing;

    if (isFollowing) {
      // Se è nello stato isFollowing true al click rimuove l'utente dalla lista dei following
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('following')
          .child(followerId)
          .remove();

      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(followerId)
          .child('followers')
          .child(currentUser.uid)
          .remove();

      await decrementFollowingCounter();
      await decrementFollowersCounter(followerId);
    } else {
      // Altrimenti, lo aggiunge ai following
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('following')
          .child(followerId)
          .set(true);

      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(followerId)
          .child('followers')
          .child(currentUser.uid)
          .set(true);

      // Incrementa il contatore dei following
      await incrementFollowingCounter();
      await incrementFollowersCounter(followerId);
    }
    // Aggiorna lo stato di isFollowing nella lista
    setState(() {
      notifiche[index].isFollowing = !isFollowing;
    });
  }

  Future<void> incrementFollowingCounter() async {
    // Ottieni il valore attuale del contatore dei following
    DatabaseReference counterRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUser.uid)
        .child('following counter');

    try {
      DataSnapshot snapshot = await counterRef.once().then((event) => event.snapshot);
      int currentCount = snapshot.value as int;
      int newCount = currentCount + 1;
      counterRef.set(newCount);
    } catch (error) {
      print('Error retrieving following counter: $error');
    }
  }

  Future<void> decrementFollowingCounter() async {
    DatabaseReference counterRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUser.uid)
        .child('following counter');

    try {
      DataSnapshot snapshot = await counterRef.once().then((event) => event.snapshot);
      int currentCount = snapshot.value as int;
      int newCount = currentCount - 1;
      counterRef.set(newCount);
    } catch (error) {
      print('Error retrieving following counter: $error');
    }
  }

  Future<void> incrementFollowersCounter(String followerId) async {
    // Ottieni il valore attuale del contatore dei following
    DatabaseReference counterRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(followerId)
        .child('followers counter');

    try {
      DataSnapshot snapshot = await counterRef.once().then((event) => event.snapshot);
      int currentCount = snapshot.value as int;
      int newCount = currentCount + 1;
      counterRef.set(newCount);
    } catch (error) {
      print('Error retrieving followers counter: $error');
    }
  }

  Future<void> decrementFollowersCounter(String followerId) async {
    DatabaseReference counterRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(followerId)
        .child('followers counter');

    try {
      DataSnapshot snapshot = await counterRef.once().then((event) => event.snapshot);
      int currentCount = snapshot.value as int;
      int newCount = currentCount - 1;
      counterRef.set(newCount);
    } catch (error) {
      print('Error retrieving follower counter: $error');
    }
  }

  void startReviewListener() {
    FirebaseDatabase.instance
        .ref()
        .child('reviews')
        .onChildAdded
        .listen((event) {
      // Ottiene l'ID della recensione
      String reviewId = event.snapshot.key ?? "";
      // Ottiene le informazioni sulla recensione in modo asincrono
      getReviewData(reviewId);
    });

    FirebaseDatabase.instance
        .ref()
        .child('reviews')
        .onChildRemoved
        .listen((event) {
      // Ottieni l'ID della recensione
      String reviewId = event.snapshot.key ?? "";
      // Rimuove la notifica relativa alla recensione
      removeReviewNotification(reviewId);
    });
  }

  void removeReviewNotification(String reviewId) {
    setState(() {
      notifiche.removeWhere((notifica) => notifica.reviewId == reviewId);
    });
  }

  void removeReviewsByUserId(String userId) {
    setState(() {
      notifiche.removeWhere((notifica) =>
      notifica.tipo == TipoNotifica.nuovaRecensione &&
          notifica.userId == userId);
    });
  }

  void getReviewData(String reviewId) async {
    DatabaseReference reviewRef = FirebaseDatabase.instance
        .ref()
        .child('reviews')
        .child(reviewId);
    DataSnapshot reviewSnapshot = await reviewRef.once().then((event) => event.snapshot);
    Map<dynamic, dynamic>? reviewData = reviewSnapshot.value as Map<dynamic, dynamic>?;

    if (reviewData != null) {
      String reviewerId = reviewData['userId'] ?? "";
      String trackId = reviewData['trackId'] ?? "";
      String timestampString = reviewData['timestamp'] ?? "";
      // Converte la stringa del timestamp in un oggetto DateTime
      DateTime timestamp = DateTime.parse(timestampString);

      DatabaseReference trackRef = FirebaseDatabase.instance
          .ref()
          .child('tracks')
          .child(trackId);
      DataSnapshot trackSnapshot = await trackRef.once().then((event) => event.snapshot);
      Map<dynamic, dynamic>? trackData = trackSnapshot.value as Map<dynamic, dynamic>?;

      if (trackData != null) {
        String trackName = trackData['name'] ?? "";

        DataSnapshot followingSnapshot = await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(currentUser.uid)
            .child('following')
            .child(reviewerId)
            .once().then((event) => event.snapshot);
        bool isFollowing = followingSnapshot.exists;

        if (isFollowing) {
          DatabaseReference reviewerRef = FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(reviewerId);
          DataSnapshot reviewerSnapshot = await reviewerRef.once().then((event) => event.snapshot);
          Map<dynamic, dynamic>? reviewerData = reviewerSnapshot.value as Map<dynamic, dynamic>?;

          if (reviewerData != null) {
            String reviewerName = reviewerData['name'] ?? "";
            String reviewerProfileImage = reviewerData['profile image'] ?? "";

            String? immagineProfilo;
            if (reviewerProfileImage.isNotEmpty) {
              immagineProfilo = reviewerProfileImage;
            }

            setState(() {
              notifiche.add(
                Notifica(
                  tipo: TipoNotifica.nuovaRecensione,
                  reviewId: reviewId,
                  mittente: reviewerName,
                  userId: reviewerId,
                  testo: "ha scritto una nuova recensione della canzone \"$trackName\"",
                  immagineProfilo: immagineProfilo,
                  immagineDefault: Icons.account_circle,
                  isFollowing: isFollowing,
                  timestamp: timestamp,
                  trackId: trackId,
                ),
              );
            });
          }
        }
      }
    }
  }
  Future<Track> fetchTrack(String trackId) async {
    print('Fetching track with ID: $trackId');

    try {
      // Interroga il database per ottenere i dati della traccia
      DataSnapshot dataSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('tracks')
          .child(trackId)
          .once()
          .then((event) => event.snapshot);

      // Verifica che i dati esistano
      if (dataSnapshot.exists) {
        // Ottiene i dati come mappa generica
        Map<dynamic, dynamic> trackDataDynamic = dataSnapshot.value as Map<dynamic, dynamic>;
        // Converte la mappa in una mappa di tipo String, dynamic
        Map<String, dynamic> trackDataStringKeys = trackDataDynamic.map((key, value) => MapEntry(key.toString(), value));




        // Recupero dal db della lista degli artistId non compatibili con il metodo
        //from json e trasormazione della lista di stringhe in lista di oggetti
        List<String> artistIds = List<String>.from(trackDataStringKeys['artists']);


        // Per ogni ID, recupera i dettagli dell'artista
        List<Artist> artists = [];
        for (String artistId in artistIds) {
          Artist? artist = await retrieveArtistById(artistId);
          if (artist != null) {
            artists.add(artist);
            print("vediamo cosa c'è nelle notifiche ${artists.first.name}");
          }
        }

        // Assegna la lista degli artisti con tutti i dati all'oggetto Track
        trackDataStringKeys['artists'] = artists;

        trackDataStringKeys['artists'] = artistIds.map((id) => {"id": id}).toList();

        // Crea un'istanza di Track utilizzando i dati ottenuti dal database
        Track track = Track.fromJson(trackDataStringKeys);

        // Log per visualizzare i dati della traccia convertita
        print('Converted track data: ${track.artists.first.name}');

        return track;
      } else {
        throw Exception('Track data not found for ID: $trackId');
      }
    } catch (error) {
      print('Error fetching track: $error');
      rethrow;
    }
  }
  Future<Artist?> retrieveArtistById(String artistId) async {
    final database = FirebaseDatabase.instance.ref();
    final artistRef = database.child('artists').child(artistId);

    DatabaseEvent event = await artistRef.once();

    if (event.snapshot.exists) {
      // Converte il dataSnapshot in un Map<String, dynamic>
      Map<String, dynamic> artistData = Map<String, dynamic>.from(event.snapshot.value as Map);
      artistData['id'] = artistId;
      return Artist.fromJson(artistData);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Ordina le notifiche delle recensioni per timestamp
    List<Notifica> recensioni = notifiche.where((notifica) => notifica.tipo == TipoNotifica.nuovaRecensione).toList();
    recensioni.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('See Your Music'),
      ),
      body: ListView.builder(
        itemCount: notifiche.length,
        itemBuilder: (context, index) {
          return GestureDetector(
              onTap: () {
            // Logica di clickbasata sul tipo di notifica
            if (notifiche[index].tipo == TipoNotifica.nuovoFollower) {
              // Naviga al profilo del follower
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaginaAmico(userId: notifiche[index].userId),
                ),
              );
            } else if (notifiche[index].tipo == TipoNotifica.nuovaRecensione) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FutureBuilder<Track?>(
                    future: fetchTrack(notifiche[index].trackId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center( child: SizedBox(height: 40, width: 40, child: CircularProgressIndicator(),),);
                      } else if (snapshot.hasError || snapshot.data == null) {
                        return Text('Error fetching track');
                      } else {
                        return BranoSelezionato(track: snapshot.data!);
                      }
                    },
                  ),
                ),
              );
            } else {
              print('Track ID is null');
            }
          },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[800],
                backgroundImage: notifiche[index].immagineProfilo != null && notifiche[index].immagineProfilo!.isNotEmpty
                    ? NetworkImage(notifiche[index].immagineProfilo!)
                    : null,
                child: notifiche[index].immagineProfilo == null
                    ? Icon(notifiche[index].immagineDefault, color: Colors.white,)
                    : null,
              ),
              title: Text(
                  '${notifiche[index].mittente} ${notifiche[index].testo}'),
              trailing: notifiche[index].tipo == TipoNotifica.nuovoFollower
                  ? ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Cambia lo stato di follow/unfollow
                          toggleFollowStatus(notifiche[index].userId, index);
                        });
                      },
                      child: Text(notifiche[index].isFollowing ? "Unfollow" : "Follow"),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}