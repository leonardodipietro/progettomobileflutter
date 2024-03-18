import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:progettomobileflutter/pagina_amico.dart';

class Follower {
  final String userId;
  final String username;
  final String profileImageUrl;

  Follower({
    required this.userId,
    required this.username,
    required this.profileImageUrl,
  });
}

class FollowersList extends StatefulWidget {
  @override
  _FollowersListState createState() => _FollowersListState();
}

class _FollowersListState extends State<FollowersList> {
  late List<Follower> followerIds = []; // Lista dei follower
  late Map<String, Map<String, dynamic>> followersInfo = {
  }; // Mappa contenente le informazioni dei follower

  @override
  void initState() {
    super.initState();
    fetchFollowerIds();
  }

  // Funzione per recuperare la lista degli ID dei follower dall'utente corrente
  void fetchFollowerIds() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference followersRef = FirebaseDatabase.instance.ref().child(
          'users').child(user.uid).child('followers');
      try {
        DataSnapshot snapshot = await followersRef.once().then((event) =>
        event.snapshot);
        if (snapshot.value != null) {
          Map<dynamic, dynamic> followerMap = snapshot.value as Map<
              dynamic,
              dynamic>;
          List<String> followerIds = followerMap.keys.cast<String>().toList();
          fetchFollowersInfo(followerIds);
        }
      } catch (error) {
        print('Error fetching follower IDs: $error');
      }
    }
  }

  // Funzione per recuperare le informazioni dei follower
  void fetchFollowersInfo(List<dynamic> followerIds) async {
    for (String followerId in followerIds) {
      DatabaseReference userRef = FirebaseDatabase.instance.ref()
          .child('users')
          .child(followerId);
      try {
        DataSnapshot snapshot = await userRef.once().then((event) =>
        event.snapshot);
        if (snapshot.value != null) {
          Map<String, dynamic> followerData = Map<String, dynamic>.from(
              snapshot.value as Map<dynamic, dynamic>);
          Follower follower = Follower(
            userId: followerData['userId'],
            username: followerData['name'],
            profileImageUrl: followerData['profile image'],
          );

          // Log follower information
          print('Follower ID: $followerId');
          print('Follower Data: $followerData');
          print('Follower Object: $follower');

          setState(() {
            // Add follower info to followersInfo map, not to followerIds list
            followersInfo[followerId] = followerData;
          });
        }
      } catch (error) {
        print('Error fetching follower info: $error');
      }
    }
  }

  void removeFollower(String followerId) async {
    setState(() {
      // Rimuovi il follower dalla mappa followersInfo
      followersInfo.remove(followerId);
    });

    // Aggiorna anche il database per riflettere la rimozione del follower
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference followersRef = FirebaseDatabase.instance.ref().child(
          'users').child(user.uid).child('followers');
      try {
        await followersRef.child(followerId).remove();
        print("Follower removed successfully");

        // Aggiorna il contatore dei follower nel database
        DatabaseReference userRef = FirebaseDatabase.instance.ref().child(
            'users').child(user.uid);
        DataSnapshot snapshot = await userRef.child('followers counter')
            .once()
            .then((event) => event.snapshot);
        int currentFollowerCount = snapshot.value != null ? snapshot
            .value as int : 0;
        await userRef.update({'followers counter': currentFollowerCount - 1});
      } catch (error) {
        print("Error removing follower: $error");
      }

      // Rimuovi te stesso dalla lista dei "following" del follower
      DatabaseReference followingRef = FirebaseDatabase.instance.ref().child(
          'users').child(followerId).child('following');
      try {
        await followingRef.child(user.uid).remove();
        print("You removed from follower's following list successfully");

        // Aggiorna il contatore dei following del follower nel database
        DatabaseReference followerRef = FirebaseDatabase.instance.ref().child(
            'users').child(followerId);
        DataSnapshot snapshot = await followerRef.child('following counter')
            .once()
            .then((event) => event.snapshot);
        int currentFollowingCount = snapshot.value != null ? snapshot
            .value as int : 0;
        await followerRef.update(
            {'following counter': currentFollowingCount - 1});
      } catch (error) {
        print("Error removing yourself from follower's following list: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Followers'),
      ),
      body: followersInfo
          .isEmpty // Mostra l'indicatore di caricamento solo se la lista dei follower è vuota
          ? Center(
            child: followersInfo.isNotEmpty
              ? CircularProgressIndicator()
              : FutureBuilder(
                future: Future.delayed(Duration(seconds: 10)), // Timeout dopo 5 secondi
                builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
                } else {
                return Text("Non hai ancora nessun follower");
                }
              },
            ),
          )
          : ListView.builder(
        itemCount: followersInfo.length,
        itemBuilder: (BuildContext context, int index) {
          String followerId = followersInfo.keys.toList()[index];
          Map<String, dynamic> followerData = followersInfo[followerId]!;
          Follower follower = Follower(
            userId: followerData['userId'],
            username: followerData['name'],
            profileImageUrl: followerData['profile image'],
          );
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaginaAmico(userId: followerId),
                ),
              );
              },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[800],
                backgroundImage: followerData['profile image'] != null &&
                    followerData['profile image'].isNotEmpty
                    ? NetworkImage(
                    followerData['profile image']) // Utilizza l'immagine del profilo se presente
                    : AssetImage(
                    'assets/profile_default_image.jpg') as ImageProvider<Object>,
                // Utilizza l'immagine predefinita se l'URL è vuoto
                child: followerData['profile image'] == null ||
                    followerData['profile image'].isEmpty
                    ? Icon(Icons
                    .account_circle) // Mostra l'icona predefinita se non c'è un'immagine del profilo
                    : null,
              ),
              title: Text(follower.username),
              trailing: ElevatedButton(
                onPressed: () {
                  // Chiedi conferma all'utente
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Remove Follower"),
                        content: Text(
                            "Are you sure you want to remove this follower?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Chiudi il dialog
                            },
                            child: Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              // Rimuovi il follower
                              removeFollower(followerId);
                              Navigator.of(context).pop(); // Chiudi il dialog
                            },
                            child: Text("Remove"),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text("Remove"),
              ),
            ),
          );
        },
      ),
    );
  }
}