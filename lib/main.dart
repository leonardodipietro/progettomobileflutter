import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:progettomobileflutter/viewmodel/SpotifyViewModel.dart';
import 'package:progettomobileflutter/api/SpotifyRepository.dart';
import 'package:progettomobileflutter/api/SpotifyConfig.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart';

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
  SpotifyViewModel? _spotifyViewModel;
  StreamSubscription? _sub;
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

  @override
  //INIZIA IL CICLO DI VITA DEL WIDGET
  void initState() {
    super.initState();
    _spotifyViewModel = SpotifyViewModel(
        SpotifyRepository(),
        SpotifyConfig.clientId,
        SpotifyConfig.clientSecret,
        SpotifyConfig.redirectUri
    );
    _initUniLinks();
  }

  void _initUniLinks() async {
    // Ascolta gli URI in arrivo quando l'app è già aperta è UN LISTENER
    _sub = getUriLinksStream().listen((Uri? uri) { //TODO IN FUTURO POTREBBE ESSERE DEPRECATA
      print('URI in arrivo: $uri');
      if (uri != null) {
        // Esegui l'autenticazione con il codice di autorizzazione dopo che è arrivato l uri
        _handleIncomingUri(uri);
      }
    }, onError: (err) {
      print('Errore nel listener URI: $err');

    });


  }

  void _handleIncomingUri(Uri uri) async {
    print('Gestione URI: $uri');
    // Estrai il codice di autorizzazione dall'URI
    final code = uri.queryParameters['code'];
    if (code != null) {
      // Utilizza il ViewModel per autenticare con il codice
      await _spotifyViewModel?.authenticate(code);
      print('Autenticazione completata');//uso l await per aspettare che venga recuperato il codice prima di chiamare fetch
      _fetchAndDisplayTopTracks();
      _fetchAndDisplayTopArtists();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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
            ElevatedButton(
              onPressed: () => _startAuthenticationProcess(context),
              child: const Text('Autentica con Spotify'),
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
  void _startAuthenticationProcess(BuildContext context) {
    // Costruisci l'URL di autenticazione
    final String authUrl = 'https://accounts.spotify.com/authorize'
        '?response_type=code'
        '&client_id=${SpotifyConfig.clientId}'
        '&redirect_uri=${Uri.encodeComponent(SpotifyConfig.redirectUri)}'
        '&scope=user-read-private%20user-read-email%20user-top-read';

    // Apri l'URL nel browser
    launch(authUrl);

    print('Apertura URL di autenticazione: $authUrl');
  }
  void _fetchAndDisplayTopTracks() async {
    if (_spotifyViewModel != null) {
      try {
        List<Track> tracks = await _spotifyViewModel!.fetchTopTracks('medium_term', 50);
        for (var track in tracks) {
          print("Track: ${track.name}, Artist: ${track.artists[0].name}, Album ${track.album.name}");
        }
      } catch (e) {
        print("Errore: $e");
      }
    } else {
      print("Errore: SpotifyViewModel non è inizializzato.");
    }
  }

  void _fetchAndDisplayTopArtists() async {
    if (_spotifyViewModel != null) {
      try {
        List<Artist> artists = await _spotifyViewModel!.fetchTopArtists('medium_term', 50);
        for (var artist in artists) {
          print("Artist : ${artist.name} ");
        }
      } catch (e) {
        print("Errore: $e");
      }
    } else {
      print("Errore: SpotifyViewModel non è inizializzato.");
    }
  }
}


