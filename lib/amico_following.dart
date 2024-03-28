import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:progettomobileflutter/pagina_amico.dart';

class amicoFollowingList extends StatefulWidget {
  final String userId;

  amicoFollowingList(this.userId);

  @override
  _amicoFollowingListState createState() => _amicoFollowingListState();
}

class _amicoFollowingListState extends State<amicoFollowingList> {
  late Map<String, Map<String, dynamic>> followingInfo = {};
  late Map<String, bool> followingStatus = {};

  @override
  void initState() {
    super.initState();
    fetchFollowingIds();
  }

  void fetchFollowingIds() async {
    // Utilizza widget.userId per accedere all'ID dell'utente corrente
    String userId = widget.userId;
    if (userId != null) {
      DatabaseReference followingRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('following');
      try {
        DataSnapshot snapshot =
        await followingRef.once().then((event) => event.snapshot);
        if (snapshot.value != null) {
          Map<dynamic, dynamic> followingMap =
          snapshot.value as Map<dynamic, dynamic>;
          List<String> followingIds =
          followingMap.keys.cast<String>().toList();
          fetchFollowingInfo(followingIds);
        }
      } catch (error) {
        print('Error fetching following IDs: $error');
      }
    }
  }

  void fetchFollowingInfo(List<String> followingIds) async {
    for (String followingId in followingIds) {
      DatabaseReference userRef =
      FirebaseDatabase.instance.ref().child('users').child(followingId);
      try {
        DataSnapshot snapshot =
        await userRef.once().then((event) => event.snapshot);
        if (snapshot.value != null) {
          Map<String, dynamic> followingData =
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
          setState(() {
            followingInfo[followingId] = followingData;
            followingStatus[followingId] = true;
          });
        } else {
          print(
              'Following data for $followingId is not in the expected format');
        }
      } catch (error) {
        print('Error fetching following info: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Following'),
      ),
      body: followingInfo
          .isEmpty // Mostra l'indicatore di caricamento solo se la lista dei seguiti è vuota
          ? Center(
        child: followingInfo.isNotEmpty
            ? CircularProgressIndicator()
            : FutureBuilder(
          future: Future.delayed(Duration(seconds: 10)), // Timeout dopo 5 secondi
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else {
              return Text("Non hai ancora nessun seguito");
            }
          },
        ),
      )
          : ListView.builder(
        itemCount: followingInfo.length,
        itemBuilder: (BuildContext context, int index) {
          String followingId = followingInfo.keys.toList()[index];
          Map<String, dynamic> followingData = followingInfo[followingId]!;
          bool isFollowing = followingStatus[followingId] ?? false;
          return GestureDetector(
              onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaginaAmico(userId: followingId),
              ),
            );
          },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[800],
                backgroundImage: followingData['profile image'] != null &&
                    followingData['profile image'].isNotEmpty
                    ? NetworkImage(
                    followingData['profile image']) // Utilizza l'immagine del profilo se presente
                    : AssetImage(
                    'assets/profile_default_image.jpg') as ImageProvider<Object>,
                // Utilizza l'immagine predefinita se l'URL è vuoto
                child: followingData['profile image'] == null ||
                    followingData['profile image'].isEmpty
                    ? Icon(Icons
                    .account_circle, color: Colors.white) // Mostra l'icona predefinita se non c'è un'immagine del profilo
                    : null,
              ),
              title: Text(followingData['name']),
            ),
          );
        },
      ),
    );
  }
}