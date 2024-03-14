import 'package:flutter/material.dart';
import 'cerca_utenti.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PaginaAmico extends StatefulWidget {
  final String userId;

  const PaginaAmico({Key? key, required this.userId}) : super(key: key);

  @override
  _PaginaAmicoState createState() => _PaginaAmicoState();
}

class _PaginaAmicoState extends State<PaginaAmico> {
  late Future<Map<String, dynamic>?> _userDataFuture;
  String _name = ''; // Variabile per memorizzare il nome dell'amico
  String _profileImage = '';
  int _reviewsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;

  bool _isLoggedIn = false;
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _userDataFuture = fetchUserData(widget.userId);
    _userDataFuture.then((userData) {
      setState(() {
        if (userData != null) {
          _name = userData['name'] ?? '';
          _profileImage = userData['profile image'] ?? '';
          _reviewsCount = userData['reviews'] ?? 0;
          _followersCount = userData['followers'] ?? 0;
          _followingCount = userData['following'] ?? 0;
        }
      });
    });
    checkUserLoggedIn();
    fetchCounters();
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
            _name, style: TextStyle(fontSize: 20),
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
              padding: const EdgeInsets.all(16.0),
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
                          onPressed: () {
                            // Azione per il pulsante "Filtro"
                          },
                          child: Text('Filtro'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Azione per il pulsante "Top Tracks"
                          },
                          child: Text('Top Tracks'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Azione per il pulsante "Top Artist"
                          },
                          child: Text('Top Artist'),
                        ),
                      ],
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
