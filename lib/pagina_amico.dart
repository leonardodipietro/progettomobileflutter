import 'package:flutter/material.dart';
import 'cerca_utenti.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:progettomobileflutter/viewmodel/FirebaseViewModel.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart' as Spotify;
import 'model/SpotifyModel.dart';
import 'package:flutter/widgets.dart' as fw;
import 'package:progettomobileflutter/BranoSelezionato.dart';
import 'package:progettomobileflutter/ArtistaSelezionato.dart';

class PaginaAmico extends StatefulWidget {
  final String userId;

  const PaginaAmico({Key? key, required this.userId}) : super(key: key);

  @override
  _PaginaAmicoState createState() => _PaginaAmicoState();
}

enum ContentType { tracks, artists }

class _PaginaAmicoState extends State<PaginaAmico> {
  late Future<Map<String, dynamic>?> _userDataFuture;
  String _name = ''; // Variabile per memorizzare il nome dell'amico
  String _profileImage = '';
  int _reviewsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;

  bool _isLoggedIn = false;
  late StreamSubscription<User?> _authSubscription;

  // Dichiarazione di _firebaseViewModel
  FirebaseViewModel _firebaseViewModel = FirebaseViewModel();

  String filter='short_term';

  List<Track> _tracksToShow = []; // Dichiarazione di _tracksToShow
  List<Artist> _artistsToShow = []; // Dichiarazione di _artistsToShow
  ContentType _contentType = ContentType.tracks;

  @override
  void initState() {
    super.initState();
    _userDataFuture = fetchUserData(widget.userId);
    _userDataFuture.then((userData) {
      setState(() {
        if (userData != null) {
          _name = userData['name'] ?? '';
          _profileImage = userData['profile image'] ?? '';
          _reviewsCount = userData['reviews counter'] ?? 0;
          _followersCount = userData['followers counter'] ?? 0;
          _followingCount = userData['following counter'] ?? 0;
        }
      });
    });
    checkUserLoggedIn();
    fetchCounters();

    // Inizializzazione di _firebaseViewModel
    _firebaseViewModel = FirebaseViewModel();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  // Funzione per verificare se l'utente è già autenticato
  void checkUserLoggedIn() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      print('User: $user'); // Stampa il valore di user
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

  // Funzione per recuperare i contatori dal database
  void fetchCounters() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DatabaseReference counterRef = FirebaseDatabase.instance.ref().child('users').child(user.uid);
        counterRef.onValue.listen((event) {
          DataSnapshot snapshot = event.snapshot;
          dynamic counters = snapshot.value;
          if (counters != null) {
            setState(() {
              _reviewsCount = counters['reviews counter'] ?? 0;
              _followersCount = counters['followers counter'] ?? 0;
              _followingCount = counters['following counter'] ?? 0;
            });
          }
        }, onError: (error) {
          print('Errore durante il recupero dei contatori: $error');
        });
      } catch (error) {
        print('Errore durante il recupero dei contatori: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _name,
          style: TextStyle(fontSize: 20),
        ), // Utilizza il nome recuperato come titolo dell'AppBar
      ),
      body: FutureBuilder(
        future: _userDataFuture,
        builder: (context, snapshot) {
          // Implementa il corpo della pagina usando il nome e altri dati recuperati
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Errore durante il recupero dei dati'),
            );
          } else {
            // Esegui il rendering del corpo della pagina qui, utilizzando i dati recuperati
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_profileImage.isNotEmpty)
                        CircleAvatar(
                          backgroundImage: NetworkImage(_profileImage),
                          radius: 40,
                        )
                      else
                        CircleAvatar(
                          // Imposta un'immagine di default se _profileImage è vuoto
                          child: Icon(Icons.account_circle, size: 80),
                          backgroundColor: Colors.grey, // Imposta un colore di sfondo grigio
                          radius: 40,
                        ),
                      _buildCounter(context, 'Reviews', _reviewsCount), // Contatore per le recensioni
                      _buildCounter(context, 'Followers', _followersCount), // Contatore per i follower
                      _buildCounter(context, 'Following', _followingCount), // Contatore per i seguiti
                      SizedBox(width: 16),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Altri widget per visualizzare ulteriori dettagli dell'amico
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => selectFilter(context),
                          child: Text('Filtro'),
                        ),
                        ElevatedButton(
                          onPressed: () => handleTrackButtonClicked(context),
                          child: Text('Top Tracks'),
                        ),
                        ElevatedButton(
                          onPressed: () => handleArtistButtonClicked(context),
                          child: Text('Top Artist'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _contentType == ContentType.tracks
                        ? GridView.count(
                      crossAxisCount: 3,
                      children: List.generate(_tracksToShow.length, (index) {
                        // Widget per tracce
                        Spotify.Track track = _tracksToShow[index];
                        return InkWell(
                          onTap: () {
                            print("Traccia selezionata: ${track.name}");
                            _navigateToBranoSelezionato(track);
                          },
                          child: Center(
                            child: Column(
                              children: [
                                track.album.images.isNotEmpty
                                    ? fw.Image.network( // Utilizza l'alias fw per Image di Flutter
                                  track.album.images[0].url,
                                  height: 100,
                                  width: 100,
                                )
                                    : Container(
                                    height: 100,
                                    width: 100,
                                    color: Colors.grey),
                                Flexible(
                                  child: Text(
                                    track.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                    )
                        : GridView.count(
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
                                    ? fw.Image.network( // Utilizza l'alias fw per Image di Flutter
                                  artist.images[0].url,
                                  height: 100,
                                  width: 100,
                                )
                                    : Container(
                                    height: 100,
                                    width: 100,
                                    color: Colors.grey),
                                Flexible(
                                  child: Text(
                                    artist.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
        }
        },
      ),
    );
  }

  // Per grafica contatori
  Widget _buildCounter(BuildContext context, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Aggiungi spaziatura orizzontale tra i contatori
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  Future<void> selectFilter(BuildContext context) async {
    BuildContext dialogContext;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        dialogContext = context; // Memorizza il contesto corrente
        return AlertDialog(
          title: Text("Seleziona Filtro"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text('Short Term'),
                  onTap: () async {
                    applyFilter(dialogContext, 'short_term'); // Utilizza il contesto memorizzato
                    Navigator.of(dialogContext).pop(); // Chiudi il popup
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Medium Term'),
                  onTap: () async {
                    applyFilter(dialogContext, 'medium_term');
                    Navigator.of(dialogContext).pop();
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Long Term'),
                  onTap: () async {
                    applyFilter(dialogContext, 'long_term');
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> applyFilter(BuildContext context, String newFilter) async {
    showDialog(
      context: context,
      builder: (context) => Center(child: CircularProgressIndicator()), // Mostra un indicatore di caricamento
    );

    // Utilizza widget.userId per ottenere lo userId necessario
    String userId = widget.userId;

    // Aggiungi lo userId necessario alla funzione fetchTopTracksFriend
    await _firebaseViewModel.fetchTopTracksFriend(userId, newFilter);

    // Aggiungi lo userId necessario alla funzione fetchTopArtistsFriend
    await _firebaseViewModel.fetchTopArtistsFriend(userId, newFilter);

    setState(() {
      _tracksToShow = _firebaseViewModel.tracksFromDb;
      _artistsToShow = _firebaseViewModel.artistsFromDb;
    });
  }

  Future<void> handleTrackButtonClicked(BuildContext context) async {
    print("Handle track button clicked chiamata");
    // Utilizza widget.userId per ottenere lo userId necessario
    String userId = widget.userId;
    await _firebaseViewModel.fetchTopTracksFriend(userId, filter);
    setState(() {
      _contentType = ContentType.tracks;
      _tracksToShow= _firebaseViewModel.tracksFromDb;
    });
  }

  Future<void> handleArtistButtonClicked(BuildContext context) async {
    // Utilizza widget.userId per ottenere lo userId necessario
    String userId = widget.userId;
    print("Handle artist button clicked chiamata");
    await _firebaseViewModel.fetchTopArtistsFriend(userId, filter);
    setState(() {
      _contentType = ContentType.artists;
      _artistsToShow= _firebaseViewModel.artistsFromDb;
    });
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

// Recupera i dati dell'utente dal database
Future<Map<String, dynamic>?> fetchUserData(String userId) async {
  try {
    DatabaseReference reference = FirebaseDatabase.instance.reference().child('users').child(userId);
    DataSnapshot snapshot = (await reference.once()).snapshot;
    Map<dynamic, dynamic>? userData = snapshot.value as Map<dynamic, dynamic>?;

    return userData?.cast<String, dynamic>(); // Cast a <String, dynamic>
  } catch (e) {
    print('Errore durante il recupero dei dati dell\'utente: $e');
    return null; // Gestisci l'errore in modo appropriato
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Cerca Utenti',
    initialRoute: '/',
    routes: {
      '/': (context) => CercaUtentiPage(),
      '/pagina_amico': (context) => PaginaAmico(userId: ''),
    },
  ));
}
