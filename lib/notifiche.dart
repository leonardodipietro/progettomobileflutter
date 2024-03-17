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
  final IconData immagineDefault;// Icona di default nel caso in cui non ci sia un'immagine del profilo
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
    currentUser = FirebaseAuth.instance.currentUser!;
    startFollowerListener();
    startFollowingListener();
    startReviewListener();
  }

  void addNewFollowerNotification(String followerId, bool isFollowing) {
    // Aggiungi la notifica contenente l'ID dell'utente alla lista
    setState(() {
      notifiche.add(
        Notifica(
          tipo: TipoNotifica.nuovoFollower,
          mittente: "Nuovo Follower",
          testo: "Ha iniziato a seguirti.",
          userId: followerId,
          immagineProfilo: null,
          // Immagine del profilo (puoi aggiungere se necessario)
          immagineDefault: Icons.account_circle,
          isFollowing: isFollowing,
        ),
      );
    });
  }

  void checkNewFollower(String followerId) {
    // Query per controllare se il followerId è un nuovo follower
    // Esegui la logica per verificare se followerId è un nuovo follower
    bool isNewFollower = true; // Esempio di logica di controllo per determinare se il followerId è un nuovo follower
    if (isNewFollower) {
      // Se followerId è un nuovo follower, aggiungi la notifica
      checkFollowingStatus(followerId);
      print(
          'Nuovo utente: $followerId'); // Stampa l'id del nuovo utente nella console
      // Controlla se il follower è tra i tuoi following
      checkFollowingStatus(followerId);
    }
  }

  Future<void> checkFollowingStatus(String followerId) async {
    // Controlla se l'ID del follower è presente tra i tuoi following
    DataSnapshot snapshot = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUser.uid)
        .child('following')
        .child(followerId)
        .once().then((event) => event.snapshot);
    bool isFollowing = snapshot.exists;

    // Aggiungi la notifica dopo aver ottenuto lo stato di seguimento
    addNewFollowerNotification(followerId, isFollowing);

    // Qui puoi fare ciò che vuoi con il valore di isFollowing
    // Ad esempio, puoi aggiornare lo stato del pulsante o fare altre azioni in base al risultato
    if (isFollowing) {
      print('Il follower $followerId è già tra i tuoi following');
      // Qui puoi fare altre azioni come aggiornare lo stato del pulsante a "unfollow"
      // Qui puoi fare altre azioni come aggiornare lo stato del pulsante a "unfollow"
      getReviewData(followerId); // Aggiungi questa riga qui
    } else {
      print('Il follower $followerId non è tra i tuoi following');
      // Qui puoi fare altre azioni come aggiornare lo stato del pulsante a "follow"
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
      String followerId = event.snapshot.key ?? ""; // Ottieni l'ID del nuovo follower
      // Ottieni le informazioni del follower in modo asincrono
      getFollowerData(followerId);
    });

    FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUser.uid)
        .child('followers')
        .onChildRemoved
        .listen((event) {
      String followerId = event.snapshot.key ?? ""; // Ottieni l'ID del follower rimosso
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
      String followingUserId = event.snapshot.key ?? ""; // Ottieni l'ID dell'utente che sta seguendo
      // Aggiorna lo stato di seguimento nelle notifiche
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
      // Rimuovi le notifiche relative alle recensioni dell'utente rimosso
      removeReviewsByUserId(removedUserId);
      // Aggiorna lo stato di seguimento nelle notifiche
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
    // Ottieni le informazioni del follower
    DatabaseReference followerRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(followerId);
    DataSnapshot followerSnapshot = await followerRef.once().then((event) => event.snapshot);
    Map<dynamic, dynamic>? followerData = followerSnapshot.value as Map<dynamic, dynamic>?;

    if (followerData != null) {
      // Estrai le informazioni necessarie dal nodo del follower
      String followerName = followerData['name'] ?? ''; // Esempio: nome del follower
      String followerProfileImage = followerData['profile image'] ?? ''; // Esempio: immagine del profilo del follower

      // Verifica se followerProfileImage è una stringa non vuota
      String? immagineProfilo;
      if (followerProfileImage.isNotEmpty) {
        immagineProfilo = followerProfileImage;
      }

      // Verifica se il follower è tra i tuoi following
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
      // Se è già seguito, rimuovi dalla lista dei following
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
      // Altrimenti, aggiungilo ai following
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
    // Aggiorna lo stato di seguimento nella lista
    setState(() {
      notifiche[index].isFollowing = !isFollowing;
    });
  }

/*  void reloadNotifications() {
    // Funzione per ricaricare le notifiche delle recensioni dei nuovi following
    notifiche.clear(); // Pulisci la lista delle notifiche
    startFollowerListener();
    startFollowingListener();
    startReviewListener(); // Riavvia il listener delle recensioni per ottenere le notifiche aggiornate
  }*/

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
      print('Error retrieving following counter: $error');
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
      print('Error retrieving following counter: $error');
    }
  }

  void startReviewListener() {
    FirebaseDatabase.instance
        .ref()
        .child('reviews')
        .onChildAdded
        .listen((event) {
      // Ottieni l'ID della recensione
      String reviewId = event.snapshot.key ?? "";
      // Ottieni le informazioni sulla recensione in modo asincrono
      getReviewData(reviewId); // Passa l'ID della recensione invece dell'ID del follower
    });

    FirebaseDatabase.instance
        .ref()
        .child('reviews')
        .onChildRemoved
        .listen((event) {
      // Ottieni l'ID della recensione
      String reviewId = event.snapshot.key ?? "";
      // Rimuovi la notifica relativa alla recensione
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
      // Converti la stringa del timestamp in un oggetto DateTime
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

      // Ottieni i dati come mappa generica
      Map<dynamic, dynamic> trackData = dataSnapshot.value as Map<dynamic, dynamic>;

      // Converti la mappa in una mappa di tipo String, dynamic
      Map<String, dynamic> trackDataStringKeys = Map<String, dynamic>.from(trackData);

      // Crea un'istanza di Track utilizzando i dati ottenuti dal database
      Track track = Track.fromJson(trackDataStringKeys);

      // Aggiungi un log per visualizzare i dati della traccia convertita
      print('Converted track data: $track');

      return track;
    } catch (error) {
      print('Error fetching track: $error');
      throw error;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ordina le notifiche delle recensioni per timestamp
    List<Notifica> recensioni = notifiche.where((notifica) => notifica.tipo == TipoNotifica.nuovaRecensione).toList();
    recensioni.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifiche'),
      ),
      body: ListView.builder(
        itemCount: notifiche.length,
        itemBuilder: (context, index) {
          return GestureDetector(
              onTap: () {
            // Logic to handle tap based on notification type
            if (notifiche[index].tipo == TipoNotifica.nuovoFollower) {
              // Navigate to follower profile
              // Replace the code below with your navigation logic
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaginaAmico(userId: notifiche[index].userId),
                ),
              );
            } else if (notifiche[index].tipo == TipoNotifica.nuovaRecensione) {
              // Navigate to track page
              // Replace the code below with your navigation logic
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FutureBuilder<Track?>(
                    future: fetchTrack(notifiche[index].trackId!), // Assuming reviewId is the trackId
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // Or a loading indicator
                      } else if (snapshot.hasError || snapshot.data == null) {
                        return Text('Error fetching track'); // Handle errors or null track
                      } else {
                        return BranoSelezionato(track: snapshot.data!); // Use the fetched track
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
                backgroundImage: notifiche[index].immagineProfilo != null && notifiche[index].immagineProfilo!.isNotEmpty
                    ? NetworkImage(notifiche[index].immagineProfilo!)
                    : null,
                child: notifiche[index].immagineProfilo == null
                    ? Icon(notifiche[index].immagineDefault)
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