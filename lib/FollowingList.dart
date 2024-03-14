import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FollowingList extends StatefulWidget {
  @override
  _FollowingListState createState() => _FollowingListState();
}

class _FollowingListState extends State<FollowingList> {
  late Map<String, Map<String, dynamic>> followingInfo = {};
  late Map<String, bool> followingStatus = {};

  @override
  void initState() {
    super.initState();
    fetchFollowingIds();
  }

  void fetchFollowingIds() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference followingRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
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

  void toggleFollowStatus(String userId) async {
    setState(() {
      followingStatus[userId] = !(followingStatus[userId] ?? false);
    });

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      if (followingStatus[userId]!) {
        // Seguire l'utente
        DatabaseReference followingRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(currentUser.uid)
            .child('following')
            .child(userId);
        DatabaseReference followerRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(userId)
            .child('followers')
            .child(currentUser.uid);

        try {
          await followingRef.set(true);
          await followerRef.set(true);
          print('Successfully followed user $userId');

          // Incrementa il contatore dei following per l'utente corrente
          DatabaseReference currentUserFollowingRef = FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(currentUser.uid)
              .child('following counter');
          DataSnapshot currentUserFollowingSnapshot = await currentUserFollowingRef
              .once().then((event) => event.snapshot);
          int currentUserFollowingCount = (currentUserFollowingSnapshot.value ??
              0) as int;
          await currentUserFollowingRef.set(currentUserFollowingCount + 1);

          // Incrementa il contatore dei followers per l'utente seguito
          DatabaseReference userBeingFollowedFollowersRef = FirebaseDatabase
              .instance
              .ref()
              .child('users')
              .child(userId)
              .child('followers counter');
          DataSnapshot userBeingFollowedFollowersSnapshot = await userBeingFollowedFollowersRef
              .once().then((event) => event.snapshot);
          int userBeingFollowedFollowersCount = (userBeingFollowedFollowersSnapshot
              .value ?? 0) as int;
          await userBeingFollowedFollowersRef.set(
              userBeingFollowedFollowersCount + 1);
        } catch (error) {
          print('Error following user $userId: $error');
        }
      } else {
        // Smettere di seguire l'utente
        DatabaseReference followingRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(currentUser.uid)
            .child('following')
            .child(userId);
        DatabaseReference followerRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(userId)
            .child('followers')
            .child(currentUser.uid);

        try {
          await followingRef.remove();
          await followerRef.remove();
          print('Successfully unfollowed user $userId');

          // Decrementa il contatore dei following per l'utente corrente
          DatabaseReference currentUserFollowingRef = FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(currentUser.uid)
              .child('following counter');
          DataSnapshot currentUserFollowingSnapshot = await currentUserFollowingRef
              .once().then((event) => event.snapshot);
          int currentUserFollowingCount = (currentUserFollowingSnapshot.value ??
              0) as int;
          await currentUserFollowingRef.set(currentUserFollowingCount - 1);

          // Decrementa il contatore dei followers per l'utente seguito
          DatabaseReference userBeingUnfollowedFollowersRef = FirebaseDatabase
              .instance
              .ref()
              .child('users')
              .child(userId)
              .child('followers counter');
          DataSnapshot userBeingUnfollowedFollowersSnapshot = await userBeingUnfollowedFollowersRef
              .once().then((event) => event.snapshot);
          int userBeingUnfollowedFollowersCount = (userBeingUnfollowedFollowersSnapshot
              .value ?? 0) as int;
          await userBeingUnfollowedFollowersRef.set(
              userBeingUnfollowedFollowersCount - 1);
        } catch (error) {
          print('Error unfollowing user $userId: $error');
        }
      }
    }
  }

  /*void unfollowUser(String userId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DatabaseReference followingRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('following')
          .child(userId);
      DatabaseReference followerRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('followers')
          .child(currentUser.uid);

      try {
        await followingRef.remove();
        await followerRef.remove();
        print('Successfully unfollowed user $userId');

        // Decrement following counter for current user
        DatabaseReference currentUserFollowingRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(currentUser.uid)
            .child('following counter');
        DataSnapshot currentUserFollowingSnapshot = await currentUserFollowingRef.once().then((event) => event.snapshot);
        int currentUserFollowingCount = currentUserFollowingSnapshot.value as int;
        await currentUserFollowingRef.set(currentUserFollowingCount - 1);

        // Decrement followers counter for user being unfollowed
        DatabaseReference userBeingUnfollowedFollowersRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(userId)
            .child('followers counter');
        DataSnapshot userBeingUnfollowedFollowersSnapshot = await userBeingUnfollowedFollowersRef.once().then((event) => event.snapshot);
        int userBeingUnfollowedFollowersCount = userBeingUnfollowedFollowersSnapshot.value as int;
        await userBeingUnfollowedFollowersRef.set(userBeingUnfollowedFollowersCount - 1);

        setState(() {
          followingInfo.remove(userId);
        });
      } catch (error) {
        print('Error unfollowing user $userId: $error');
      }
    }
  }*/

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
                  return Text("Non hai ancora nessun follower");
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
          return ListTile(
            leading: CircleAvatar(
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
                  .account_circle) // Mostra l'icona predefinita se non c'è un'immagine del profilo
                  : null,
            ),
            title: Text(followingData['name']),
            trailing: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(isFollowing
                          ? "Unfollow User"
                          : "Follow User"),
                      // Aggiorna il titolo del dialogo in base allo stato corrente
                      content: Text(isFollowing
                          ? "Are you sure you want to unfollow this user?"
                          : "Are you sure you want to follow this user?"),
                      // Aggiorna il testo del dialogo in base allo stato corrente
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Chiudi il dialog
                          },
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            // Cambia lo stato di follow/unfollow
                            toggleFollowStatus(followingId);
                            Navigator.of(context).pop(); // Chiudi il dialog
                          },
                          child: Text(isFollowing
                              ? "Unfollow"
                              : "Follow"), // Aggiorna il testo del pulsante in base allo stato corrente
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(isFollowing
                  ? "Unfollow"
                  : "Follow"), // Aggiorna il testo del pulsante in base allo stato corrente
            ),
          );
        },
      ),
    );
  }
}