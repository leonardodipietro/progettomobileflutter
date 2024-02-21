import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:progettomobileflutter/viewmodel/SpotifyViewModel.dart';
import 'package:progettomobileflutter/api/SpotifyRepository.dart';
import 'package:progettomobileflutter/api/SpotifyConfig.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart';
import 'package:progettomobileflutter/viewmodel/FirebaseViewModel.dart';

import 'package:firebase_auth/firebase_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Verifica lo stato di autenticazione dell'utente
  User? user = FirebaseAuth.instance.currentUser;
  Widget initialPage;

  // Se l'utente è già autenticato, vai direttamente alla schermata principale
  if (user != null) {
    initialPage = MyHomePage(title: 'Home');
  } else {
    initialPage = RegistrationPage();
  }

  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: initialPage,
  ));
}

/*Future<UserCredential> signInWithGoogle(BuildContext context) async {
  // Avvia il flusso di autenticazione
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

  // Ottieni i dettagli di autenticazione dalla richiesta
  final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

  // Crea una nuova credenziale
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth?.accessToken,
    idToken: googleAuth?.idToken,
  );

  // Una volta autenticato, restituisci il UserCredential
  return await FirebaseAuth.instance.signInWithCredential(credential);
}*/


// Function to create a new user account with email and password
void registerWithEmailAndPassword(context, String email, String password) async {
  try {
    // Create a new user account with email and password
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Optionally, you can handle additional steps after successful account creation here,
    // such as sending a verification email or storing additional user information.

    print('Account created successfully! User ID: ${credential.user?.uid}');

    // After registration, navigate to the home page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Home')),
    );
  } on FirebaseAuthException catch (e) {
    // Handle FirebaseAuthException errors
    if (e.code == 'weak-password') {
      print('The password provided is too weak.');
    } else if (e.code == 'email-already-in-use') {
      print('The account already exists for that email.');
    } else {
      // Handle other FirebaseAuthException errors
      print('Error creating account: ${e.message}');
    }
  } catch (e) {
    // Handle other errors
    print('Error creating account: $e');
  }
}

// Function to sign in a user with email and password
void signInWithEmailAndPassword(BuildContext context, String email, String password) async {
  try {
    // Sign in the user with email and password
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Optionally, you can handle additional steps after successful sign-in here.

    print('User signed in successfully! User ID: ${credential.user?.uid}');

    // After signing in, navigate to the home page or any other desired screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Home')),
    );
  } on FirebaseAuthException catch (e) {
    // Handle FirebaseAuthException errors
    if (e.code == 'user-not-found') {
      print('No user found for that email.');
    } else if (e.code == 'wrong-password') {
      print('Wrong password provided for that user.');
    } else {
      // Handle other FirebaseAuthException errors
      print('Error signing in: ${e.message}');
    }
  } catch (e) {
    // Handle other errors
    print('Error signing in: $e');
  }
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
      home: RegistrationPage(),

    );

  }
}

class RegistrationPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrazione'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Call the signInWithEmailAndPassword function with the email and password entered by the user
                signInWithEmailAndPassword(
                  context,
                  emailController.text,
                  passwordController.text,
                );
              },
              child: const Text('Accedi'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Call the registerWithEmailAndPassword function with the email and password entered by the user
                registerWithEmailAndPassword(
                  context,
                  emailController.text,
                  passwordController.text,
                );
              },
              child: const Text('Registrati'),
            ),
            // const SizedBox(height: 16),
            // ElevatedButton(
            //   onPressed: () {
            //     // Call the registerWithGoogle function
            //     signInWithGoogle(context);
            //   },
            //   child: const Text('Registrati con Google'),
            // ),
          ],
        ),
      ),
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
  bool _isLoggedIn = false; // Variabile di stato per gestire l'autenticazione

  SpotifyViewModel? _spotifyViewModel;
  StreamSubscription? _sub;
  int _counter = 0;
  final FirebaseViewModel _firebaseViewModel = FirebaseViewModel();

  @override
  //INIZIA IL CICLO DI VITA DEL WIDGET
  void initState() {
    super.initState();
    // Verifica se l'utente è già autenticato all'avvio dell'app
    checkUserLoggedIn();

    _spotifyViewModel = SpotifyViewModel(
        SpotifyRepository(),
        SpotifyConfig.clientId,
        SpotifyConfig.clientSecret,
        SpotifyConfig.redirectUri
    );
    _initUniLinks();
  }

  // Funzione per verificare se l'utente è già autenticato
  void checkUserLoggedIn() {
    // Utilizza FirebaseAuth per controllare lo stato di autenticazione dell'utente
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // Se l'utente è autenticato, imposta _isLoggedIn su true
        setState(() {
          _isLoggedIn = true;
        });
      } else {
        // Se l'utente non è autenticato, imposta _isLoggedIn su false
        setState(() {
          _isLoggedIn = false;
        });
      }
    });
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
      // Utilizza il ViewModel per ottenere gli ID e i nomi utente
      List<String> userIds = await _firebaseViewModel.getUserIds();
      print("User IDs from Realtime Database: $userIds");

      Map<String, String> userNames = await _firebaseViewModel.getUserNames(userIds);
      print("User Names from Realtime Database: $userNames");

      // ... Il resto del codice rimane invariato ...
    } catch (error) {
      // ... Il resto del codice rimane invariato ...
    }
  }

  // Funzione per il sign-out
  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Aggiorna lo stato di autenticazione
      setState(() {
        _isLoggedIn = false;
      });
      // Dopo il sign-out, puoi navigare l'utente alla pagina di login o ad un'altra schermata
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegistrationPage()), // Esempio di navigazione alla pagina di login
      );
    } catch (e) {
      // Gestisci eventuali errori durante il sign-out
      print('Errore durante il sign-out: $e');
    }
  }

  void _deleteAccount() async {
    try {
      // Ottieni l'utente attualmente autenticato
      User? user = FirebaseAuth.instance.currentUser;

      // Chiedi conferma all'utente prima di procedere con l'eliminazione dell'account
      bool confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Conferma"),
            content: const Text("Sei sicuro di voler eliminare completamente il tuo account? Questa azione non può essere annullata."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Chiudi il dialog e ritorna false
                },
                child: const Text("Annulla"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(true); // Chiudi il dialog e ritorna true
                },
                child: const Text("Elimina"),
              ),
            ],
          );
        },
      );

      // Se l'utente ha confermato l'eliminazione, procedi con la rimozione dell'account
      if (confirm == true) {
        // Elimina l'account dell'utente
        await user?.delete();

        // Dopo l'eliminazione dell'account, puoi navigare l'utente alla pagina di login o ad altre schermate
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RegistrationPage()), // Esempio di navigazione alla pagina di login
        );
      }
    } catch (e) {
      // Gestisci eventuali errori durante l'eliminazione dell'account
      print('Errore durante l\'eliminazione dell\'account: $e');
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
              child: const Text('Get User Data'),
            ),
            ElevatedButton(
              onPressed: () => _startAuthenticationProcess(context),
              child: const Text('Autentica con Spotify'),
            ),
            if (_isLoggedIn) // Mostra il bottone "Sign Out" solo se l'utente è autenticato
              ElevatedButton(
                onPressed: _signOut,
                child: const Text('Sign Out'),
              ),
            ElevatedButton( // Aggiunto il nuovo bottone per eliminare l'account
              onPressed: _deleteAccount,
              child: const Text('Delete Account'),
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
    var timeRanges = ["short_term", "medium_term", "long_term"];
    if (_spotifyViewModel != null) {
      for (var timeRange in timeRanges) {
        try {
          List<Track> tracks = await _spotifyViewModel!.fetchTopTracks(timeRange, 50);
          for (var track in tracks) {
            print("Track: ${track.name}, Artist: ${track.artists[0].name}, Album ${track.album.name}");
          }
          await _firebaseViewModel.saveTracksToMainNode(tracks);
          print("Tracks saved to Firebase!");
          print("//////////////////////////");
        } catch (e) {
           print("Errore: $e");
        }
      }


    }
   }


  void _fetchAndDisplayTopArtists() async {
    var timeRanges = ["short_term", "medium_term", "long_term"];
    if (_spotifyViewModel != null) {
      for (var timeRange in timeRanges) {
      try {
        List<Artist> artists = await _spotifyViewModel!.fetchTopArtists(timeRange, 50);
        for (var artist in artists) {
          print("Artist : ${artist.name} ");
        }
        await _firebaseViewModel.saveArtistsToMainNode(artists);
        print("ARtists saved to Firebase!");
        print("//////////////////////////");
      } catch (e) {
        print("Errore: $e");
      }
    }
  }}
}


