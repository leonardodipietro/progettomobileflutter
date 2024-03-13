import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:progettomobileflutter/viewmodel/SpotifyViewModel.dart' ;
import 'package:progettomobileflutter/api/SpotifyRepository.dart';
import 'package:progettomobileflutter/api/SpotifyConfig.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart' as Spotify;
import 'package:progettomobileflutter/viewmodel/FirebaseViewModel.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cerca_utenti.dart';
import 'model/SpotifyModel.dart';
import 'profilo_personale.dart';
import 'notifiche.dart';
import 'package:progettomobileflutter/BranoSelezionato.dart';
import 'package:progettomobileflutter/ArtistaSelezionato.dart';
//Importante
import 'package:flutter/material.dart' hide Image;//Utilizza un alias per non avere conflitto con l'Image di SpotifyModel
import 'package:flutter/widgets.dart' as fw;
//import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  // Assicura che i binding Flutter siano inizializzati correttamente
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Verifica lo stato di autenticazione dell'utente
  User? user = FirebaseAuth.instance.currentUser;

  Widget initialPage;

  // Se l'utente è già autenticato, vai direttamente alla schermata principale
  if (user != null) {
    initialPage = const MyHomePage(title: 'Home');
  } else {
    initialPage = RegistrationPage();
  }

  // Pagina iniziale dell'applicazione

  // Se l'utente è già autenticato, vai direttamente alla schermata principale
  if (user != null) {
    initialPage = MyHomePage(title: 'Home');
  } else {
    initialPage = RegistrationPage();
  }

  // Avvia l'applicazione Flutter passando la pagina iniziale
  runApp(MyApp(initialPage: initialPage));
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
void registerWithEmailAndPassword(context, String name, String email, String password) async {
  try {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update user profile with the provided name
    await credential.user?.updateDisplayName(name);
    await credential.user!.reload(); // Ensure the update is applied
    final userUpdated = FirebaseAuth.instance.currentUser; // Re-fetch updated user

    if (userUpdated != null) {
      // Proceed with saving the user details
      await FirebaseFirestore.instance.collection('users').doc(userUpdated.uid).set({
        'name': name, // Use the name directly from the parameter
      });

      final FirebaseViewModel _firebaseViewModel = FirebaseViewModel();
      await _firebaseViewModel.saveUserIdToFirebase(userUpdated.uid);

      print('Account created successfully! User ID: ${userUpdated.uid}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyApp(initialPage: MyHomePage(title: 'Home'))),
      );
    } else {
      print("Error: User update failed.");
    }
  } on FirebaseAuthException catch (e) {
    // Handle FirebaseAuthException errors
    // Your existing error handling
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

    final FirebaseViewModel _firebaseViewModel = FirebaseViewModel();
    await _firebaseViewModel.saveUserIdToFirebase(credential.user!.uid);

    // Optionally, you can handle additional steps after successful sign-in here.

    print('User signed in successfully! User ID: ${credential.user?.uid}');

    // After signing in, navigate to the home page or any other desired screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyApp(initialPage: MyHomePage(title: 'Home'))),
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

class MyApp extends StatefulWidget {
  final Widget initialPage; // Pagina iniziale dell'applicazione

  // Costruttore della classe MyApp
  const MyApp({required this.initialPage, Key? key}) : super(key: key);

  @override
  // Metodo per creare lo stato associato all'istanza di MyApp
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Indice corrente per gestire la navigazione
  int _currentIndex = 0;

  late BuildContext materialAppContext; // Contesto dell'applicazione MaterialApp
  late GlobalKey<NavigatorState> navigatorKey; // Chiave globale per il navigatore

  @override
  void initState() {
    super.initState();
    // Inizializzazione della chiave del navigatore
    navigatorKey = GlobalKey<NavigatorState>();
    // Inizializzazione del contesto dell'applicazione MaterialApp
    materialAppContext = context;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Assegna la chiave globale al navigatore
      title: 'Flutter Demo',
      theme: ThemeData(
        // Impostazione del tema dell'applicazione
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        // Imposta il colore delle icone nella barra di navigazione
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.deepPurple, // Colore delle icone selezionate
          unselectedItemColor: Colors.grey, // Colore delle icone non selezionate
        ),
      ),
      home: Scaffold(
        body: IndexedStack( // Utilizziamo IndexedStack per mantenere lo stato delle pagine
          index: _currentIndex, // L'indice corrente determina quale pagina viene visualizzata
          children: [
            MyHomePage(title: 'Home'),
            CercaUtentiPage(),
            NotifichePage(),
            ProfiloPersonale(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar( // Barra di navigazione nella parte inferiore dello schermo
          items: const <BottomNavigationBarItem>[ // Elementi della barra di navigazione
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifiche',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _currentIndex, // Indice corrente della barra di navigazione
          // Gestisce il tap sugli elementi della barra di navigazione
          onTap: (index) {
            // Verifica se l'indice selezionato è diverso dall'indice corrente
            if (index != _currentIndex) {
              setState(() {
                // Aggiorna l'indice corrente con l'indice selezionato
                _currentIndex = index;
              });
            }
          },
        ),
      ),
    );
  }
}

class RegistrationPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
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
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
              ),
            ),
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
                // Call the registerWithEmailAndPassword function with name, email, and password entered by the user
                registerWithEmailAndPassword(
                  context,
                  nameController.text,
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
enum ContentType { tracks, artists }//per salvare l ultima delle lista selezionate tra tracks e artists
class _MyHomePageState extends State<MyHomePage> {
  bool _isLoggedIn = false; // Variabile di stato per gestire l'autenticazione
  List<Track> _tracksToShow=[];
  List<Artist> _artistsToShow=[];
  ContentType _contentType = ContentType.tracks;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  SpotifyViewModel? _spotifyViewModel;
  StreamSubscription? _sub;
  int _counter = 0;
  final FirebaseViewModel _firebaseViewModel = FirebaseViewModel();
  String filter='short_term';
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

  /*
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
*/
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FirebaseViewModel>.value(
      // Fornisce l'istanza esistente di FirebaseViewModel
        value: _firebaseViewModel,

    child: Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: <Widget>[
            //const Text('User IDs and Names from Realtime Database:'),
            /*ElevatedButton(
              onPressed: () => _startAuthenticationProcess(context),
              child: const Text('Autentica con Spotify'),
            ),
            */
           Center(
            child: ElevatedButton(
                   onPressed: () => _onHandleStartAuthButtonClick(),
                   child: const Text('Autentica con Spotify'),
            ),
           ),
            Container(
              width: double.infinity, // Occupa tutta la larghezza possibile
              color: Theme.of(context).colorScheme.secondary, // Colore di sfondo
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Padding interno
              child: Row( // Usa Row per allineare i bottoni orizzontalmente
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Spazia uniformemente i bottoni
                children: [
                  ElevatedButton(
                    onPressed: () => selectFilter(),
                    child: Text('Filtro'),
                  ),
                  ElevatedButton(
                    onPressed: () => handleTrackButtonClicked(),
                    child: Text('Top Tracks'),
                  ),
                  ElevatedButton(
                    onPressed: () => handleArtistButtonClicked(),
                    child: Text('Top Artist'),
                  ),
                  /*DA METTERE ElevatedButton(
                    child:Text('stile'),
                    onPressed:() => print('bottone premuto'),
                  ),*/
                ],
              ),
            ),
            SizedBox(height: 15),
            Expanded(
              child: _contentType == ContentType.tracks ? GridView.count(
                crossAxisCount: 3,
                children: List.generate(_tracksToShow.length, (index) {
                  // Widget per tracce
                  Spotify.Track track = _tracksToShow[index];
                  return InkWell(//widget che rende cliccabile elemento
                      onTap: () {
                        print("Traccia selezionata: ${track.name}");
                        _navigateToBranoSelezionato(track);
                      },
                  child: Center(
                    child: Column(
                      children: [
                        track.album.images.isNotEmpty
                            ? fw.Image.network(track.album.images[0].url, height: 100, width: 100) // Utilizza l'alias fw per Image di Flutter
                            : Container(height: 100, width: 100, color: Colors.grey),
                        Flexible(
                          child:Text(
                            track.name,
                            overflow: TextOverflow.ellipsis,//serve per evitare l overflow del testo
                          )
                          /*VEDIAMO se LASCIARLO
                          child:Column(
                          children: [Text(_tracksToShow[index].name,
                                          overflow: TextOverflow.ellipsis),
                                     Text(_tracksToShow[index].artists.map((artist) => artist.name).join(", "),
                                       overflow: TextOverflow.ellipsis,
                                       ),
                                      Text(_tracksToShow[index].album.name,
                                        overflow: TextOverflow.ellipsis,
                                        ),
                         ])*/
                       )
                      ],
                    ),
                  ),
                  );
                }),
              ) : GridView.count(
                crossAxisCount: 3,
                children: List.generate(_artistsToShow.length, (index) {
                  // Widget per artisti
                  Spotify.Artist artist = _artistsToShow[index];
                  return InkWell(
                      onTap: () {
                        print("Traccia selezionata: ${artist.name}");
                        _navigateToArtistaSelezionato(artist);
                      },

                   child: Center(
                    child: Column(
                      children: [
                        artist.images.isNotEmpty
                            ? fw.Image.network(artist.images[0].url, height: 100, width: 100) // Utilizza l'alias fw per Image di Flutter
                            : Container(height: 100, width: 100, color: Colors.grey),
                        Flexible(
                          child: Text(
                            artist.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),);
                }),
              ),
            )
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
    ));

  }

  void selectFilter() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Seleziona Filtro"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text('Short Term'),
                  onTap: () async {

                    applyFilter('short_term');
                    Navigator.of(context).pop(); // Chiude la finestra di dialogo dopo l'azione
                  },
                    /*{
                  Navigator.of(context).pop();
                    /*setState(()  {
                      /*filter = 'short_term';
                      await _firebaseViewModel.fetchTopTracksFromFirebase(filter);
                      _tracksToShow= _firebaseViewModel.tracksFromDb;*/
                    });*/
                    Navigator.of(context).pop();
                  },*/
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Medium Term'),
                  onTap: () async {

                    applyFilter('medium_term');
                    Navigator.of(context).pop(); // Chiude la finestra di dialogo dopo l'azione
                  },
                  /*{
                    /*setState(()  {
                    //  filter = 'medium_term';
                    //  _firebaseViewModel.fetchTopTracksFromFirebase(filter);
                    //  _tracksToShow= _firebaseViewModel.tracksFromDb;
                    });*/
                    Navigator.of(context).pop();
                  },*/
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Long Term'),
                  onTap: () async{
                    applyFilter('long_term');
                    Navigator.of(context).pop(); // Chiude la finestra di dialogo dopo l'azione
                  },
                   /* setState(()  {
                     /* filter = 'long_term';
                      _firebaseViewModel.fetchTopTracksFromFirebase(filter);
                      _tracksToShow= _firebaseViewModel.tracksFromDb;*/
                    });*/
                   // Navigator.of(context).pop();

                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void applyFilter(String newFilter) async {
    showDialog(
      context: context,
      builder: (context) => Center(child: CircularProgressIndicator()), // Mostra un indicatore di caricamento
    );


    await _firebaseViewModel.fetchTopTracksFromFirebase(newFilter);
    await _firebaseViewModel.fetchTopArtistsFromFirebase(newFilter);

    setState(() {
      _tracksToShow = _firebaseViewModel.tracksFromDb;
      _artistsToShow =_firebaseViewModel.artistsFromDb;
    });


  }

  Future<void> handleTrackButtonClicked() async {
    print("Handle track button clicked chiamata");
    final userId = FirebaseAuth.instance.currentUser?.uid;
    await _firebaseViewModel.fetchTopTracksFromFirebase(filter);
    setState(() {
      _contentType = ContentType.tracks;
      _tracksToShow= _firebaseViewModel.tracksFromDb;
    });
  }

  Future<void> handleArtistButtonClicked() async {
    final userId= FirebaseAuth.instance.currentUser?.uid;
    print("Handle artist button clicked chiamata");
    await _firebaseViewModel.fetchTopArtistsFromFirebase(filter);
    setState(() {
      _contentType = ContentType.artists;
      _artistsToShow= _firebaseViewModel.artistsFromDb;
    });
  }







  void checkAndSaveUserCredentials() async {
    final auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      // Utilizza il FirebaseViewModel per verificare lo stato di registrazione
      bool isRegistered = await _firebaseViewModel.checkUserIdInFirebase(userId);
      if (!isRegistered) {
        // L'utente non è registrato, quindi salva le sue credenziali
        await _firebaseViewModel.saveUserIdToFirebase(userId);
        // Aggiorna la UI o esegui altre azioni necessarie
      }
    }
  }

  void _onHandleStartAuthButtonClick() {

    final userId = FirebaseAuth.instance.currentUser?.uid;
    //se è null non si brucia l applicazione
    if (userId == null) return;
    _startAuthenticationProcess(context);
    _spotifyViewModel?.accessToken;
    getTopTracks(_spotifyViewModel?.accessToken,userId);
    //_spotifyViewModel.fetchTopTracks(timeRange, limit)
    getTopArtists(_spotifyViewModel?.accessToken,userId);
    //_observeToken();

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
  void getTopTracks(String? token, String userId) {
    print('gettotracks chiamato');
    List<String> timeRanges = ['short_term', 'medium_term', 'long_term'];
    for (var timeRange in timeRanges) {
      // Esegue fetchTopTracks in background
      Future(() async {
        await _spotifyViewModel?.fetchTopTracks(timeRange, 50);
      }).then((_) {
        // A seconda del timeRange, ascolta il rispettivo stream
        switch (timeRange) {
          case 'short_term':
            _spotifyViewModel?.shortTermTracksStream.listen(
                  (response) {
                handleResponseTrack(response, userId, timeRange);
              },
              onError: (error) {
                // Gestisci l'errore qui
                print('Errore nello stream: $error');
              },
            );
            break;
          case 'medium_term':
            _spotifyViewModel?.mediumTermTracksStream.listen(
                  (response) {
                handleResponseTrack(response, userId, timeRange);
              },
              onError: (error) {
                // Gestisci l'errore qui
                print('Errore nello stream: $error');
              },
            );
            break;


          case 'long_term':
            _spotifyViewModel?.longTermTracksStream.listen(
                  (response) {
                handleResponseTrack(response, userId, timeRange);
              },
              onError: (error) {
                // Gestisci l'errore qui
                print('Errore nello stream: $error');
              },
            );
            break;
            break;
        }
      });
    }
  }

  void getTopArtists(String? token, String userId) {
    print('gettoartists chiamato');
    List<String> timeRanges = ['short_term', 'medium_term', 'long_term'];
    for (var timeRange in timeRanges) {
      // Esegue fetchTopTracks in background
      Future(() async {
        await _spotifyViewModel?.fetchTopArtists(timeRange, 50);
      }).then((_) {
        // A seconda del timeRange, ascolta il rispettivo stream
        switch (timeRange) {
          case 'short_term':
            _spotifyViewModel?.shortTermArtistsStream.listen(
                  (response) {
                handleResponseArtist(response, userId, timeRange);
              },
              onError: (error) {
                // Gestisci l'errore qui
                print('Errore nello stream: $error');
              },
            );
            break;
          case 'medium_term':
            _spotifyViewModel?.mediumTermArtistsStream.listen(
                  (response) {
                handleResponseArtist(response, userId, timeRange);
              },
              onError: (error) {
                // Gestisci l'errore qui
                print('Errore nello stream: $error');
              },
            );
            break;


          case 'long_term':
            _spotifyViewModel?.longTermArtistsStream.listen(
                  (response) {
                handleResponseArtist(response, userId, timeRange);
              },
              onError: (error) {
                // Gestisci l'errore qui
                print('Errore nello stream: $error');
              },
            );
            break;
            break;
        }
      });
    }
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
      // _fetchAndDisplayTopTracks();
      //_fetchAndDisplayTopArtists();
    }
  }

/*// Assumendo che handleResponseTrack sia definito da qualche parte nel tuo codice Dart.
  void handleResponseTrack(dynamic response, String userId, String timeRange) {
    // Implementazione...
  }*/

  void handleResponseTrack(trackResponse,userId,timeRange) {
    print("trackresponse su handle $trackResponse");
    print("userId $userId");
    if(trackResponse!= null && userId != null) {
      //vediamo qui
      try {
        print("trackResponse è nullo? ${trackResponse == null}");
        print("userId è nullo? ${userId == null}");
        print("trackResponse.items è nullo? ${trackResponse == null}");
        print("trackResponse.items è vuoto? ${trackResponse.isEmpty}");
      } catch (e) {
        print("Si è verificata un'eccezione: $e");
      }


      print("altro per sicurezzaGGG $trackResponse ");
      if(trackResponse.isNotEmpty) {
        print("primo test contenuto $userId");
        _firebaseViewModel.saveTracksToMainNode(trackResponse);
        _firebaseViewModel.saveUserTopTracks(userId,trackResponse,timeRange);
      }
    }
  }

  void handleResponseArtist(artistResponse,userId,timeRange) {
    print("trackresponse su handle $artistResponse");
    print("userId $userId");
    if(artistResponse!= null && userId != null) {
      //vediamo qui
      try {
        print("tartistResponse è nullo? ${artistResponse == null}");
        print("userId è nullo? ${userId == null}");
        print("trackResponse.items è nullo? ${artistResponse == null}");
        print("trackResponse.items è vuoto? ${artistResponse.isEmpty}");
      } catch (e) {
        print("Si è verificata un'eccezione: $e");
      }


      print("altro per sicurezzaGGG $artistResponse ");
      if(artistResponse.isNotEmpty) {
        print("primo test contenuto $artistResponse");
        _firebaseViewModel.saveArtistsToMainNode(artistResponse);
        _firebaseViewModel.saveUserTopArtists(userId,artistResponse,timeRange);
      }
    }
  }
  void _navigateToBranoSelezionato(Spotify.Track track) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BranoSelezionato(track: track )),
    );
  }
  void _navigateToArtistaSelezionato(Spotify.Artist artist)  {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ArtistaSelezionato(artist: artist )),
    );
  }
}


/*
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
 */