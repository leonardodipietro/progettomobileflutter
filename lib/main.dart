import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future<List<String>> _getUserIds() async {
    DatabaseReference databaseReference =
    FirebaseDatabase.instance.reference().child('users');

    DataSnapshot dataSnapshot = (await databaseReference.once()).snapshot;

    if (dataSnapshot.value != null && dataSnapshot.value is Map) {
      Map<dynamic, dynamic> userData = dataSnapshot.value as Map<dynamic, dynamic>;
      List<String> userIds = userData.keys.cast<String>().toList();
      return userIds;
    } else {
      return [];
    }
  }


  Future<Map<String, String>> _getUserNames(List<String> userIds) async {
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

  void _onButtonPressed() async {
    try {
      List<String> userIds = await _getUserIds();
      print("User IDs from Realtime Database: $userIds");

      Map<String, String> userNames = await _getUserNames(userIds);
      print("User Names from Realtime Database: $userNames");

      // Aggiorna lo stato o visualizza i dati a schermo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User IDs: $userIds\nUser Names: $userNames'),
        ),
      );
    } catch (error) {
      print("Error fetching data: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('User IDs and Names from Realtime Database:'),
            ElevatedButton(
              onPressed: _onButtonPressed,
              child: Text('Get User Data'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _counter++;
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
