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

class amicoFollowersList extends StatefulWidget {
  final String userId;

  amicoFollowersList(this.userId);

  @override
  _amicoFollowersListState createState() => _amicoFollowersListState();
}

class _amicoFollowersListState extends State<amicoFollowersList> {
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
    // Utilizza widget.userId per accedere all'ID dell'utente corrente
    String userId = widget.userId;
    if (userId != null) {
      DatabaseReference followersRef = FirebaseDatabase.instance.ref().child(
          'users').child(userId).child('followers');
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


          print('Follower ID: $followerId');
          print('Follower Data: $followerData');
          print('Follower Object: $follower');

          setState(() {

            followersInfo[followerId] = followerData;
          });
        }
      } catch (error) {
        print('Error fetching follower info: $error');
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
              return Text("Non hai ancora nessun seguace");
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
                backgroundColor:Colors.grey[800],
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
                    .account_circle, color: Colors.white,)
                    : null,
              ),
              title: Text(follower.username),
            ),
          );
        },
      ),
    );
  }
}