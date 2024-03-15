import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

enum TipoNotifica {
  nuovoFollower,
  nuovaRecensione,
}

class Notifica {
  final TipoNotifica tipo;
  final String mittente;
  final String followerId;
  final String testo;
  final String? immagineProfilo;
  final IconData immagineDefault;// Icona di default nel caso in cui non ci sia un'immagine del profilo
  bool isFollowing; // Indica se l'utente corrente sta già seguendo il mittente della notifica

  Notifica({
    required this.tipo,
    required this.mittente,
    required this.followerId,
    required this.testo,
    required this.immagineProfilo,
    required this.immagineDefault,
    required this.isFollowing,
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
  }

  void addNewFollowerNotification(String followerId, bool isFollowing) {
    // Aggiungi la notifica contenente l'ID dell'utente alla lista
    setState(() {
      notifiche.add(
        Notifica(
          tipo: TipoNotifica.nuovoFollower,
          mittente: "Nuovo Follower",
          testo: "Ha iniziato a seguirti.",
          followerId: followerId,
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
              followerId: followerId,
              testo: " ha iniziato a seguirti.",
              immagineProfilo: immagineProfilo,
              immagineDefault: Icons.account_circle,
              isFollowing: isFollowing,
            ),
          );
        });
    }
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

      await decrementFollowingCounter();
    } else {
      // Altrimenti, aggiungilo ai following
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('following')
          .child(followerId)
          .set(true);

      // Incrementa il contatore dei following
      await incrementFollowingCounter();
    }
    // Aggiorna lo stato di seguimento nella lista
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifiche'),
      ),
      body: ListView.builder(
        itemCount: notifiche.length,
        itemBuilder: (context, index) {
          return ListTile(
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
            trailing: ElevatedButton(
              onPressed: () {
                setState(() {
                  // Cambia lo stato di follow/unfollow
                  toggleFollowStatus(notifiche[index].followerId, index);
                });
              },
              child: Text(notifiche[index].isFollowing ? "Unfollow" : "Follow"),
            ),
          );
        },
      ),
    );
  }
}