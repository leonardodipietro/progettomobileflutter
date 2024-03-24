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
import 'amico_reviews.dart';
import 'amico_followers.dart';
import 'amico_following.dart';

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

  List<Spotify.Track> _tracksToShow = []; // Dichiarazione di _tracksToShow
  List<Artist> _artistsToShow = []; // Dichiarazione di _artistsToShow
  ContentType _contentType = ContentType.tracks;

  bool _isFollowing = false;

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
    fetchCounters(widget.userId);

    // Inizializzazione di _firebaseViewModel
    _firebaseViewModel = FirebaseViewModel();

    // Controlla se l'utente sta seguendo l'utente attuale al momento dell'inizializzazione della pagina
    checkFollowingStatus();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  // Funzione per controllare lo stato del seguimento dell'utente attuale
  Future<void> checkFollowingStatus() async {
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentUserUid.isNotEmpty) {
      bool isFollowing = await _firebaseViewModel.isCurrentUserFollowing(widget.userId, currentUserUid);

      setState(() {
        _isFollowing = isFollowing;
      });

      print('Stato del seguimento: $_isFollowing');
    }
  }

  // Funzione per gestire il click sul pulsante "Segui"
  void handleFollowButtonClicked() {
    setState(() {
      _isFollowing = !_isFollowing; // Cambia lo stato del seguimento
    });

    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Aggiorna lo stato su Firebase in base alla tua logica di aggiunta/rimozione dai follower
    if (_isFollowing) {
      // Aggiungi l'utente ai tuoi follower su Firebase
      _firebaseViewModel.addFollower(widget.userId, currentUserUid);
      incrementFollowersCounter(widget.userId);
      incrementFollowingCounter(currentUserUid);
      print('Tu hai iniziato a seguire l\'utente con ID: ${widget.userId}');
      print('L\'utente con ID ${widget.userId} è stato aggiunto ai tuoi following');
    } else {
      // Rimuovi l'utente dai tuoi follower su Firebase
      _firebaseViewModel.removeFollower(widget.userId, currentUserUid);
      decrementFollowersCounter(widget.userId);
      decrementFollowingCounter(currentUserUid);
      print('Tu hai smesso di seguire l\'utente con ID: ${widget.userId}');
      print('L\'utente con ID ${widget.userId} è stato rimosso dai tuoi following');
    }
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
  void fetchCounters(String userId) {
      try {
        DatabaseReference counterRef = FirebaseDatabase.instance.ref().child('users').child(userId);
        counterRef.onValue.listen((event) {
          DataSnapshot snapshot = event.snapshot;
          dynamic counters = snapshot.value;
          if (counters != null) {
            setState(() {
              _reviewsCount = counters['reviews counter'] ?? 0;
              _followersCount = counters['followers counter'] ?? 0;
              _followingCount = counters['following counter'] ?? 0;
              print('Contatori: Reviews=$_reviewsCount, Followers=$_followersCount, Following=$_followingCount');
            });
          }
        }, onError: (error) {
          print('Errore durante il recupero dei contatori: $error');
        });
      } catch (error) {
        print('Errore durante il recupero dei contatori: $error');
      }
  }

  // Funzione che incrementa followers counter di userId (amico cercato)
  Future<void> incrementFollowersCounter(String userId) async {
    DatabaseReference counterRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('followers counter');

    try {
      DataSnapshot snapshot = await counterRef.once().then((event) => event.snapshot);
      int currentCount = snapshot.value as int;
      int newCount = currentCount + 1;
      counterRef.set(newCount);
      print('Contatore dei followers incrementato per l\'utente con ID $userId');
    } catch (error) {
      print('Errore durante l\'incremento del contatore dei followers per l\'utente con ID $userId: $error');
    }
  }

  // Funzione che incrementa following counter di currentUserUid (io)
  Future<void> incrementFollowingCounter(String userId) async {
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    DatabaseReference counterRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUserUid)
        .child('following counter');

    try {
      DataSnapshot snapshot = await counterRef.once().then((event) => event.snapshot);
      int currentCount = snapshot.value as int;
      int newCount = currentCount + 1;
      counterRef.set(newCount);
      print('Contatore dei followers incrementato per l\'utente con ID $userId');
    } catch (error) {
      print('Errore durante l\'incremento del contatore dei followers per l\'utente con ID $userId: $error');
    }
  }

  // Funzione che decrementa followers counter di userId (amico cercato)
  Future<void> decrementFollowersCounter(String userId) async {
    DatabaseReference counterRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('followers counter');

    try {
      DataSnapshot snapshot = await counterRef.once().then((event) => event.snapshot);
      int currentCount = snapshot.value as int;
      int newCount = currentCount - 1;
      counterRef.set(newCount);
      print('Contatore dei followers decrementato per l\'utente con ID $userId');
    } catch (error) {
      print('Errore durante il decremento del contatore dei followers per l\'utente con ID $userId: $error');
    }
  }

  // Funzione che decrementa following counter di currentUserUid (io)
  Future<void> decrementFollowingCounter(String userId) async {
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    DatabaseReference counterRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUserUid)
        .child('following counter');

    try {
      DataSnapshot snapshot = await counterRef.once().then((event) => event.snapshot);
      int currentCount = snapshot.value as int;
      int newCount = currentCount - 1;
      counterRef.set(newCount);
      print('Contatore dei followers decrementato per l\'utente con ID $userId');
    } catch (error) {
      print('Errore durante il decremento del contatore dei followers per l\'utente con ID $userId: $error');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(_name),
            ),
            ElevatedButton(
              onPressed: handleFollowButtonClicked,
              child: Text(_isFollowing ? 'Segui già' : 'Segui'), // Cambia il testo in base allo stato del seguimento
            ),
          ],
        ),
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
                          backgroundColor: _profileImage.isNotEmpty
                          ? Colors.grey[800] : Colors.transparent,
                          backgroundImage: NetworkImage(_profileImage),
                          radius: 40,
                        )
                      else
                        CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          // Imposta un'immagine di default se _profileImage è vuoto
                          child: Icon(Icons.account_circle, size: 80, color: Colors.white,),
                          radius: 40,
                        ),
                      _buildCounter(context, 'Reviews', _reviewsCount,
                        _navigateToReviews,),
                      _buildCounter(context, 'Followers', _followersCount,
                        _navigateToFollowers,),
                      _buildCounter(context, 'Following', _followingCount,
                        _navigateToFollowing,),
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

  // Per grafica contatori cliccabili
  Widget _buildCounter(BuildContext context, String label, int count, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap, // Chiamata alla funzione onTap per la navigazione
      child: Padding(
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
      ),
    );
  }

  // Gestisce la selezione del filtro temporale
  Future<void> selectFilter(BuildContext context) async {
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
                    applyFilter(context, 'short_term'); // Passa il contesto corrente
                    Navigator.of(context).pop(); // Chiude la finestra di dialogo dopo l'azione
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Medium Term'),
                  onTap: () async {
                    applyFilter(context, 'medium_term'); // Passa il contesto corrente
                    Navigator.of(context).pop(); // Chiude la finestra di dialogo dopo l'azione
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Long Term'),
                  onTap: () async{
                    applyFilter(context, 'long_term'); // Passa il contesto corrente
                    Navigator.of(context).pop(); // Chiude la finestra di dialogo dopo l'azione
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Applica il filtro temporale scelto
  Future<void> applyFilter(BuildContext context, String newFilter) async {
    showDialog(
      context: context,
      builder: (context) => Center(child: CircularProgressIndicator()), // Mostra un indicatore di caricamento
    );

    // Utilizza widget.userId per ottenere lo userId necessario
    String userId = widget.userId;

    // Chiamata per recuperare i brani
    await _firebaseViewModel.fetchTopTracksFriend(userId, newFilter);

    // Chiamata per recuperare gli artisti
    await _firebaseViewModel.fetchTopArtistsFriend(userId, newFilter);

    setState(() {
      _tracksToShow = _firebaseViewModel.tracksFromDb;
      _artistsToShow = _firebaseViewModel.artistsFromDb;
    });
  }

  // Gestisce il click su Top Tracks
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

  // Gestisce il click su Top Artist
  Future<void> handleArtistButtonClicked(BuildContext context) async {
    // Utilizza widget.userId per ottenere lo userId necessario
    String userId = widget.userId;

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
  void _navigateToReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => amicoReviewsList(widget.userId)),
    );
  }
  void _navigateToFollowers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => amicoFollowersList(widget.userId)),
    );
  }
  void _navigateToFollowing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => amicoFollowingList(widget.userId)),
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
