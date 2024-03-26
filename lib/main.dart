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
import 'package:flutter/material.dart' hide Image;//Utilizza un alias per non avere conflitto con l'Image di SpotifyModel
import 'package:flutter/widgets.dart' as fw;
import 'model/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Assicura che i binding Flutter siano inizializzati correttamente
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Verifica lo stato di autenticazione dell'utente
  User? user = FirebaseAuth.instance.currentUser;
  print('Valore di user: $user');

  Widget initialPage;

  // Se l'utente è già autenticato, vai direttamente alla schermata principale
  if (user != null) {
    initialPage = const MyApp(initialPage: MyHomePage(title: 'Home'));
  } else {
    initialPage = RegistrationPage(); //OCCHIO
  }

  // Avvia l'applicazione Flutter passando la pagina iniziale
  runApp(MyApp(initialPage: initialPage));
}

// Function to create a new user account with email and password
Future<void> registerWithEmailAndPassword(context, String name, String email, String password) async {
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
    if (e.code == 'weak-password') {
      // Password troppo debole
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('La password deve contenere almeno 6 caratteri'),
        duration: Duration(seconds: 2),
      ));
    } else if (e.code == 'email-already-in-use') {
      // Indirizzo email già utilizzato
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Questo indirizzo email è già stato utilizzato.'),
        duration: Duration(seconds: 2),
      ));
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
Future<bool> signInWithEmailAndPassword(BuildContext context, String email, String password) async {
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
    return true;
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
    return false;
  }
}

// Funzione per avviare il processo di recupero della password
Future<void> resetPassword(BuildContext context, String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    // Mostra un messaggio di successo all'utente
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Una email con istruzioni per il ripristino della password è stata inviata al tuo indirizzo email.'),
      duration: Duration(seconds: 2),
    ));
  } catch (e) {
    // Gestisci gli errori
    print('Errore durante il recupero della password: $e');
    // Mostra un messaggio di errore all'utente
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Si è verificato un errore durante il recupero della password. Si prega di riprovare più tardi.'),
      duration: Duration(seconds: 2),
    ));
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
  bool isUserAuthenticated = false;

  late BuildContext materialAppContext; // Contesto dell'applicazione MaterialApp
  late GlobalKey<NavigatorState> navigatorKey; // Chiave globale per il navigatore

  @override
  void initState() {
    super.initState();
    // Inizializzazione della chiave del navigatore
    navigatorKey = GlobalKey<NavigatorState>();
    // Inizializzazione del contesto dell'applicazione MaterialApp
    materialAppContext = context;
    checkUserAuthenticationStatus();
  }
  void checkUserAuthenticationStatus() {
    // Simula una chiamata per verificare lo stato di autenticazione dell'utente
    var user = FirebaseAuth.instance.currentUser;
    setState(() {
      isUserAuthenticated = user != null;
    });
  }
  @override
  Widget build(BuildContext context) {
    /*return MaterialApp(
      navigatorKey: navigatorKey, // Assegna la chiave globale al navigatore
      title: 'Flutter Demo',
      theme: darkTheme,*/
    // Utilizza una condizione per decidere quale pagina mostrare
    final Widget currentPage = isUserAuthenticated
        ? IndexedStack(index: _currentIndex,
      children: [
        MyHomePage(title: 'See Your Music'),
        CercaUtentiPage(),
        NotifichePage(),
        ProfiloPersonale(),
      ],
    )
        : widget.initialPage; // Mostra initialPage se l'utente non è autenticato

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: darkTheme,


      home: Scaffold(
        body: currentPage,
        bottomNavigationBar: isUserAuthenticated ? BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifiche'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Impostazioni'),
          ],
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ) : null, // Nasconde la BottomNavigationBar se l'utente non è autenticato
      ),
    );
  }
}

void checkUserLoggedIn() async {
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      print('Listener authStateChanges: Utente non loggato');
    } else {
      print('Listener authStateChanges: Utente loggato');
    }
  });
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscureText = true;

  void _togglePasswordVisibility(BuildContext context) {
    setState(() {
      _obscureText = !_obscureText;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_obscureText ? 'Password nascosta' : 'Password visibile'),
      duration: Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrazione'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Benvenuto su',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1ED660), // Colore verde
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'See Your Music',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1ED660), // Colore verde
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name',),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        _togglePasswordVisibility(context);
                      },
                    ),
                  ),
                  obscureText: _obscureText,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    // Verifica se gli altri campi sono stati compilati
                    if (nameController.text.isEmpty || emailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Si prega di compilare tutti i campi'),
                        duration: Duration(seconds: 2),
                      ));
                      return;
                    }
                    registerWithEmailAndPassword(
                      context,
                      nameController.text,
                      emailController.text,
                      passwordController.text,
                    );
                  },
                  child: Text('Registrati'),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text("Sei già registrato? Accedi"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPage createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscureText = true;

  void _togglePasswordVisibility(BuildContext context) {
    setState(() {
      _obscureText = !_obscureText;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_obscureText ? 'Password nascosta' : 'Password visibile'),
      duration: Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accesso'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Benvenuto su',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1ED660), // Colore verde
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'See Your Music',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1ED660), // Colore verde
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    _togglePasswordVisibility(context);
                  },
                ),
              ),
              obscureText: _obscureText,
            ),
            const SizedBox(height: 0),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  resetPassword(context, emailController.text);
                },
                child: Text('Password dimenticata?', style: TextStyle(fontSize: 14, color: Colors.grey),),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Controlla se entrambi i campi email e password sono stati inseriti
                if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Inserire sia l\'email che la password'),
                    duration: Duration(seconds: 2),
                  ));
                  return;
                }

                // Effettua l'accesso con email e password e ottieni il risultato
                bool signInSuccess = await signInWithEmailAndPassword(
                  context,
                  emailController.text,
                  passwordController.text,
                );

                // Se l'accesso non ha avuto successo, mostra un messaggio di errore
                if (!signInSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Una tra email e password è sbagliata'),
                    duration: Duration(seconds: 2),
                  ));
                }
              },
              child: const Text('Accedi'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Navigate back to the registration page
                Navigator.pop(context);
              },
              child: const Text("Non sei ancora registrato? Registrati"),
            ),
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
  bool isLoggedIn = false; // Variabile di stato per gestire l'autenticazione
  List<Track> _tracksToShow=[];
  List<Artist> _artistsToShow=[];
  //ContentType _contentType = ContentType.tracks;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  SpotifyViewModel? _spotifyViewModel;
  StreamSubscription? _sub;
  int counter = 0;
  final FirebaseViewModel _firebaseViewModel = FirebaseViewModel();
  //String filter='short_term';

  String term = 'short_term';
  String type = 'top tracks';
  ContentType contentType = ContentType.tracks;

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

    _loadUserPreferences();

    // Popola la lista automaticamente all'avvio dell'app
    if (contentType == ContentType.tracks) {
      print("Popolamento lista automatico: tracks, termine: $term");
      handleTrackButtonClicked(term);

    } else {
      print("Popolamento lista automatico: artists, termine: $term");
      handleArtistButtonClicked(term);
    }
  }

  _loadUserPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Carica le preferenze dell'utente, se presenti
    String savedTerm = prefs.getString('term') ?? 'short_term';
    String savedType = prefs.getString('type') ?? 'top tracks';
    int savedContentTypeIndex = prefs.getInt('contentType') ?? 0;

    // Imposta le preferenze predefinite se non sono state salvate
    term = savedTerm;
    type = savedType;
    contentType = ContentType.values[savedContentTypeIndex];

    // Stampa le preferenze caricate per controllo
    print('Termine selezionato: $term');
    print('Tipo selezionato: $type');
    print('Tipo di contenuto selezionato: $contentType');

    // Se non ci sono preferenze salvate, salva le impostazioni predefinite
    if (savedTerm == 'short_term' && savedType == 'top tracks' && savedContentTypeIndex == 0) {
      _saveUserPreferences();
    }
  }

  // Funzione per verificare se l'utente è già autenticato
  void checkUserLoggedIn() {
    // Utilizza FirebaseAuth per controllare lo stato di autenticazione dell'utente
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // Se l'utente è autenticato, imposta _isLoggedIn su true
        setState(() {
          isLoggedIn = true;
        });
      } else {
        // Se l'utente non è autenticato, imposta _isLoggedIn su false
        setState(() {
          isLoggedIn = false;
        });
      }
    });
  }

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
            title: Text(widget.title),
          ),
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: <Widget>[
                Center(
                  child: ElevatedButton(
                    onPressed: () => _onHandleStartAuthButtonClick(),
                    child: const Text('Autentica con Spotify'),
                  ),
                ),
                Container(
                  width: double.infinity, // Occupa tutta la larghezza possibile
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Padding interno
                  child: Row( // Usa Row per allineare i bottoni orizzontalmente
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Spazia uniformemente i bottoni
                    children: [
                      ElevatedButton(
                        onPressed: () => selectFilter(),
                        child: Text('Filtro'),
                      ),
                      ElevatedButton(
                        onPressed: () => handleTrackButtonClicked(term),
                        child: Text('Top Tracks'),
                      ),
                      ElevatedButton(
                        onPressed: () => handleArtistButtonClicked(term),
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
                  child: contentType == ContentType.tracks ? GridView.count(
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
                                  ? fw.Image.network(
                                track.album.images[0].url,
                                height: 100,
                                width: 100,
                                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                  // Se c'è un errore nel caricamento, mostra un'immagine di default con una decorazione
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white, // Sfondo bianco per il contrasto
                                      borderRadius: BorderRadius.circular(8), // Angoli arrotondati
                                    ),
                                    child: fw.Image.asset(
                                      'assets/images/iconabrano.jpg',
                                      height: 100,
                                      width: 100,
                                    ),
                                  );
                                },
                              )
                                  : Container(
                                decoration: BoxDecoration(
                                  color: Colors.white, // Sfondo bianco per il contrasto
                                  borderRadius: BorderRadius.circular(8), // Angoli arrotondati
                                ),
                                child: fw.Image.asset(
                                  'assets/images/iconabrano.jpg',
                                  height: 100,
                                  width: 100,
                                ),
                              ),
                              Flexible(
                                  child:Text(
                                    track.name,
                                    overflow: TextOverflow.ellipsis,//serve per evitare l overflow del testo
                                  )
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
                                  ? fw.Image.network(
                                artist.images[0].url,
                                height: 100,
                                width: 100,
                                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                  // Se c'è un errore nel caricamento, mostra un'immagine di default con una decorazione
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white, // Sfondo bianco per il contrasto
                                      borderRadius: BorderRadius.circular(8), // Angoli arrotondati
                                    ),
                                    child: fw.Image.asset(
                                      'assets/images/iconacantante.jpg',
                                      height: 100,
                                      width: 100,
                                    ),
                                  );
                                },
                              )
                                  : Container(
                                decoration: BoxDecoration(
                                  color: Colors.white, // Sfondo bianco per il contrasto
                                  borderRadius: BorderRadius.circular(8), // Angoli arrotondati
                                ),
                                child: fw.Image.asset(
                                  'assets/images/iconacantante.jpg',
                                  height: 100,
                                  width: 100,
                                ),
                              ),
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
        )
    );

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
                    _saveUserPreferences();
                    print('Termine selezionato: $term');
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Medium Term'),
                  onTap: () async {
                    applyFilter('medium_term');
                    Navigator.of(context).pop(); // Chiude la finestra di dialogo dopo l'azione
                    _saveUserPreferences();
                    print('Termine selezionato: $term');
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Long Term'),
                  onTap: () async{
                    applyFilter('long_term');
                    Navigator.of(context).pop(); // Chiude la finestra di dialogo dopo l'azione
                    _saveUserPreferences();
                    print('Termine selezionato: $term');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _saveUserPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('term', term);
    prefs.setString('type', type);
    prefs.setInt('contentType', contentType.index);

    print('Preferenze utente salvate');
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

  Future<void> handleTrackButtonClicked(String filter) async {
    print("Handle track button clicked chiamata");
    final userId = FirebaseAuth.instance.currentUser?.uid;
    await _firebaseViewModel.fetchTopTracksFromFirebase(filter);
    setState(() {
      contentType = ContentType.tracks;
      _tracksToShow= _firebaseViewModel.tracksFromDb;
      print("I dati sono stati caricati correttamente.");
    });
  }

  Future<void> handleArtistButtonClicked(String filter) async {
    final userId= FirebaseAuth.instance.currentUser?.uid;
    print("Handle artist button clicked chiamata");
    await _firebaseViewModel.fetchTopArtistsFromFirebase(filter);
    setState(() {
      contentType = ContentType.artists;
      _artistsToShow= _firebaseViewModel.artistsFromDb;
      print("I dati sono stati caricati correttamente.");
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
      print('Autenticazione completata');
      _onAuthenticationCompleted(); // Questo metodo viene chiamato qui
    }
  }
  void _onAuthenticationCompleted() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final accessToken = _spotifyViewModel?.accessToken;
    if (accessToken != null) {
      getTopTracks(accessToken, userId);
      getTopArtists(accessToken, userId);
    } else {
      print("Token di accesso non disponibile.");
    }
  }

  void getTopTracks(String? accessToken, String userId) {
    print('getTopTracks chiamato');
    List<String> timeRanges = ['short_term', 'medium_term', 'long_term'];

    for (var timeRange in timeRanges) {
      // Non è più necessario avvolgere la chiamata in un Future separato.
      _spotifyViewModel?.fetchTopTracks(accessToken!, timeRange, 50, (response, fetchedTimeRange) {
        handleResponseTrack(response, userId, fetchedTimeRange);
      });
    }
  }
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


  void getTopArtists(String? accessToken, String userId) {
    print('getTopArtists chiamato');
    List<String> timeRanges = ['short_term', 'medium_term', 'long_term'];

    for (var timeRange in timeRanges) {
      _spotifyViewModel?.fetchTopArtists(accessToken!, timeRange, 50, (response, fetchedTimeRange) {
        // Questa callback viene chiamata dopo il fetch dei dati e l'aggiornamento degli stream.
        handleResponseArtist(response, userId, fetchedTimeRange);
      });
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
