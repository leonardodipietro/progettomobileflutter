import 'dart:async';
import 'dart:io';
import 'main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:progettomobileflutter/FollowersList.dart';
import 'package:progettomobileflutter/FollowingList.dart';
import 'package:progettomobileflutter/ReviewsList.dart';

class ProfiloPersonale extends StatefulWidget {
  const ProfiloPersonale({super.key});

  @override
  _ProfiloPersonaleState createState() => _ProfiloPersonaleState();
}

class _ProfiloPersonaleState extends State<ProfiloPersonale> {
  bool _isLoggedIn = false;
  late StreamSubscription<User?> _authSubscription;
  late String? profileImageUrl= ''; // Definizione della variabile profileImageUrl
  late String? profileUsername = '';
  late String? email = '';
  int reviewCounter = 0; // Variabile di stato per il contatore delle recensioni
  int followersCounter = 0; // Variabile di stato per il contatore dei follower
  int followingCounter = 0; // Variabile di stato per il contatore dei following


  @override
  void initState() {
    super.initState();
    checkUserLoggedIn();
    fetchProfileImage();
    fetchProfileUsername();
    fetchEmail();
    fetchCounters();
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

  @override
  void dispose() {
    _authSubscription.cancel(); // Rimuovi il listener
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Stack(
            alignment: AlignmentDirectional.bottomEnd,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!) // Utilizza l'immagine del profilo corrente
                      : AssetImage('assets/profile_default_image.jpg') as ImageProvider<Object>, // Utilizza l'immagine predefinita
                  child: (!_isLoggedIn || (profileImageUrl == null || profileImageUrl!.isEmpty))? Icon(Icons.account_circle, size: 150): null, // Icona predefinita se non c'è un'immagine del profilo
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white60, // Colore di sfondo dell'IconButton
                    ),
                    child: IconButton(
                      onPressed: () => _editProfileImage(context),
                      icon: Icon(Icons.edit),
                      iconSize: 25,
                      color: Colors.black, // Colore dell'icona dell'IconButton
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    // Azione da eseguire quando viene cliccato il contatore delle recensioni
                    // Per esempio, potresti navigare a una pagina di recensioni
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReviewsList()),
                    );
                  },
                  child: _buildCounter(context, 'Reviews', reviewCounter),
                ),
                GestureDetector(
                  onTap: () {
                    // Azione da eseguire quando viene cliccato il contatore dei follower
                    // Per esempio, puoi navigare alla pagina dei follower
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FollowersList()),
                    );
                  },
                  child: _buildCounter(context, 'Followers', followersCounter),
                ),
                GestureDetector(
                  onTap: () {
                    // Azione da eseguire quando viene cliccato il contatore dei seguiti
                    // Per esempio, potresti navigare a una pagina dei seguiti
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FollowingList()),
                    );
                  },
                  child: _buildCounter(context, 'Following', followingCounter),
                ),              ],
            ),
            SizedBox(height: 20,),
            _buildUsername(context, 'Nome utente', 'JohnDoe'),
            _buildEmail(context, 'Email', 'example@domain.com'),// Voce Nome utente
            SizedBox(height: 60),
            ElevatedButton(
              onPressed: () => _signOut(context),
              child: Text('Sign Out'),
            ),
            ElevatedButton(
              onPressed: () => _deleteAccount(context),
              child: Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(BuildContext context, String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 24,),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildUsername(BuildContext context, String label, String name) {
    return Padding(
      padding: EdgeInsets.only(left: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 20),
          Row(
            children: [
              Text(
                profileUsername ?? name, // Usa profileUsername se non è nullo, altrimenti usa 'username'
                style: TextStyle(fontSize: 20),
              ),
              IconButton(
                onPressed: () => _editUsername(context),
                icon: Icon(Icons.edit),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmail(BuildContext context, String label, String name) {
    return Padding(
      padding: EdgeInsets.only(left: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 20,),
          Text(
            _abbreviateEmail(email ?? ''), // Utilizza l'operatore di null safety per gestire il valore null
            style: TextStyle(fontSize: 20),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Funzione per abbreviare l'email se è troppo lunga
  String _abbreviateEmail(String email) {
    if (email.length > 30) {
      return email.substring(0, 25) + '...'; // Abbrevia l'email e aggiunge puntini di sospensione
    } else {
      return email; // Restituisce l'email originale se non è troppo lunga
    }
  }

  //Recupera l'immagine profilo dal database
  void fetchProfileImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DatabaseReference imageUrlRef = FirebaseDatabase.instance.ref().child('users').child(user.uid).child('profile image');
        imageUrlRef.once().then((DatabaseEvent event) {
          DataSnapshot snapshot = event.snapshot;
          dynamic value = snapshot.value;
          // Verifica se lo snapshot contiene un valore
          if (value != null) {
            String? imageUrl = value as String?;
            setState(() {
              profileImageUrl = imageUrl; // Aggiorna l'URL dell'immagine del profilo
            });
          }
        }).catchError((error) {
          print('Errore durante il recupero dell\'URL dell\'immagine del profilo: $error');
        });
      } catch (error) {
        print('Errore durante il recupero dell\'URL dell\'immagine del profilo: $error');
      }
    }
  }

  //Apre il dialogue per modificare l'immagine profilo in vari modi
  void _editProfileImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Modifica immagine del profilo'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _takePhoto(); // Funzione per scattare una foto
              },
              child: Text('Scatta una foto'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _chooseFromGallery(); // Funzione per scegliere una foto dalla galleria
              },
              child: Text('Scegli dalla galleria'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _removePhoto(); // Funzione per rimuovere l'immagine corrente
              },
              child: Text('Rimuovi foto corrente'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Annulla'),
            ),
          ],
        );
      },
    );
  }

  //Permette di accede alla fotocamera per scattare una foto e impostarla come immagine di profili
  void _takePhoto() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.camera);
    if (pickedFile != null) {
      // Hai scattato una foto, ora puoi gestire il file
      File imageFile = File(pickedFile.path);

      // Carica l'immagine nel cloud storage (ad esempio, Firebase Storage)
      String imageUrl = await uploadImageToStorage(imageFile);

      // Aggiorna l'URL dell'immagine nel database dell'utente
      updateProfileImageUrl(imageUrl);
    } else {
      // L'utente ha annullato la selezione
    }
  }

  //Permette di accedere alla galleria e di scegliere un immagine profilo dalla galleria
  void _chooseFromGallery() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Hai scelto una foto dalla galleria, ora puoi gestire il file
      // Esempio: carica il file nell'immagine del profilo
      _updateProfileImage(File(pickedFile.path));
    } else {
      // L'utente ha annullato la selezione
    }
  }

  //Inserisce l'immagine profilo nello storage
  Future<String> uploadImageToStorage(File imageFile) async {
    try {
      // Ottieni l'utente corrente
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Crea un riferimento al percorso di destinazione nel cloud storage
        Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}/image.jpg');

        // Carica l'immagine nel cloud storage
        UploadTask uploadTask = storageRef.putFile(imageFile);

        // Attendi il completamento del caricamento
        await uploadTask.whenComplete(() => null);

        // Ottieni l'URL dell'immagine caricata
        String imageUrl = await storageRef.getDownloadURL();

        return imageUrl;
      } else {
        throw Exception('Utente non trovato');
      }
    } catch (e) {
      print('Errore durante il caricamento dell\'immagine nel cloud storage: $e');
      throw e; // Rilancia l'eccezione per gestirla nel chiamante
    }
  }

  // Funzione per inserire l'URL dell'immagine scattata nel database dell'utente (Firebase Realtime Database)
  void updateProfileImageUrl(String imageUrl) {
    try {
      // Ottieni l'utente corrente
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Ottieni il riferimento al nodo dell'immagine del profilo dell'utente nel database
        DatabaseReference imageUrlRef = FirebaseDatabase.instance.ref().child('users').child(user.uid).child('profile image');

        // Aggiorna l'URL dell'immagine nel database
        imageUrlRef.set(imageUrl).then((_) {
          // Aggiornamento completato con successo
          print('URL dell\'immagine del profilo aggiornato con successo nel database');
          fetchProfileImage();
        }).catchError((error) {
          // Gestisci gli errori nell'aggiornamento
          print('Errore durante l\'aggiornamento dell\'URL dell\'immagine del profilo nel database: $error');
        });
      } else {
        throw Exception('Utente non trovato');
      }
    } catch (e) {
      print('Errore durante l\'aggiornamento dell\'URL dell\'immagine del profilo nel database: $e');
      throw e; // Rilancia l'eccezione per gestirla nel chiamante
    }
  }

  // Funzione per inserire l'URL dell'immagine presa dalla galleria nel database dell'utente (Firebase Realtime Database)
  void _updateProfileImage(File imageFile) async {
    try {
      // Carica l'immagine nel cloud storage (ad esempio, Firebase Storage)
      String imageUrl = await uploadImageToStorage(imageFile);

      // Aggiorna l'URL dell'immagine nel database dell'utente
      updateProfileImageUrl(imageUrl);
      fetchProfileImage();
    } catch (e) {
      // Gestisci eventuali errori
      print('Errore durante il caricamento dell\'immagine del profilo dalla galleria: $e');
    }
  }

  //Rimuove l'immagine di profilo dal database, in questo modo viene mostrata l'immagine di default
  void _removePhoto() {
    // Ottieni l'utente corrente
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Ottieni il riferimento al nodo dell'immagine del profilo dell'utente nel database
        DatabaseReference imageUrlRef = FirebaseDatabase.instance.ref().child('users').child(user.uid).child('profile image');

        // Rimuovi completamente il nodo "profile image" dal database
        imageUrlRef.remove().then((_) {
          // Aggiorna anche la variabile locale profileImageUrl
          setState(() {
            profileImageUrl = null; // Imposta l'URL dell'immagine del profilo su vuoto
          });
          // Visualizza un messaggio di successo o effettua altre azioni necessarie
        }).catchError((error) {
          // Gestisci gli errori in caso di fallimento nell'eliminazione dal database
          print('Errore durante l\'eliminazione del nodo "profile image" dal database: $error');
        });
      } catch (error) {
        // Gestisci eventuali errori durante il recupero del riferimento nel database
        print('Errore durante il recupero del riferimento nel database: $error');
      }
    }
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
              reviewCounter = counters['reviews counter'] ?? 0;
              followersCounter = counters['followers counter'] ?? 0;
              followingCounter = counters['following counter'] ?? 0;
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

  //Recupera il nome utente dal database
  void fetchProfileUsername() async {
    print('Inizio fetchProfileUsername()');
    User? user = FirebaseAuth.instance.currentUser;
    print('Valore di user: $user'); // Stampa il valore di user
    if (user != null) {
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(user.uid).child('name');
      userRef.onValue.listen((event) {
        print('Listener degli eventi del database attivato');
        DataSnapshot snapshot = event.snapshot;
        dynamic value = snapshot.value;
        print('Snapshot: $value'); // Controlla il valore del snapshot
        if (value != null && value is String) {
          setState(() {
            profileUsername = value;
          });
          print('Nome utente recuperato: $profileUsername');
        } else {
          print('Il campo "name" non è presente o è null nel database.');
        }
      }, onError: (error) {
        print('Errore durante il recupero dell\'name: $error');
      });
    }
  }

  //Permette la modifica del nome utente
  void _editUsername(BuildContext context) {
    // Mostra un dialogo per la modifica del nome utente
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newName = ''; // Variabile per memorizzare il nuovo nome utente

        return AlertDialog(
          title: Text("Modifica nome"),
          content: TextField(
            onChanged: (value) {
              newName = value; // Aggiorna il nuovo nome utente ogni volta che viene modificato
            },
            decoration: InputDecoration(hintText: "Inserisci il tuo nome"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Chiudi il dialogo senza effettuare modifiche
              },
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                // Verifica se il nuovo nome utente non è vuoto
                if (newName.isNotEmpty) {
                  // Ottieni l'utente attualmente autenticato
                  User? user = FirebaseAuth.instance.currentUser;

                  // Ottieni il riferimento al campo 'name' nel database
                  DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(user!.uid).child('name');

                  // Effettua l'aggiornamento del nome utente nel database
                  userRef.set(newName).then((_) {
                    setState(() {
                      profileUsername = newName; // Aggiorna il nome utente visualizzato nell'UI
                    });
                    Navigator.of(context).pop(); // Chiudi il dialogo dopo l'aggiornamento
                  }).catchError((error) {
                    print("Errore durante l'aggiornamento del nome utente: $error");
                  });
                }
              },
              child: Text('Conferma'),
            ),
          ],
        );
      },
    );
  }

  void fetchEmail() async {
    print('Inizio fetchEmail()');
    User? user = FirebaseAuth.instance.currentUser;
    print('Valore di user: $user'); // Stampa il valore di user
    if (user != null) {
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(user.uid).child('email');
      userRef.onValue.listen((event) {
        print('Listener degli eventi del database attivato');
        DataSnapshot snapshot = event.snapshot;
        dynamic value = snapshot.value;
        print('Snapshot: $value'); // Controlla il valore del snapshot
        if (value != null && value is String) {
          setState(() {
            email = value;
          });
          print('Email recuperata: $email');
        } else {
          print('Il campo "email" non è presente o è null nel database.');
        }
      }, onError: (error) {
        print('Errore durante il recupero dell\'name: $error');
      });
    }
  }

  // Funzione per il sign-out
  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Reset dello stato dell'autenticazione
      setState(() {
        _isLoggedIn = false;
      });
      // Navigazione alla pagina di registrazione
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegistrationPage()),
      );
    } catch (e) {
      // Gestione degli errori
      print('Errore durante il sign-out: $e');
    }
  }

  // Funzione per eliminare l'account
  void _deleteAccount(BuildContext context) async {
    try {
      // Ottieni l'utente attualmente autenticato
      User? user = FirebaseAuth.instance.currentUser;

      // Chiedi conferma all'utente prima di procedere con l'eliminazione dell'account
      bool? confirm = await showDialog<bool>(
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
                onPressed: () {
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

        // Rimuovi anche il nodo relativo all'utente corrente dal Realtime Database
        final reference = FirebaseDatabase.instance.ref().child('users').child(user!.uid);
        await reference.remove();

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
}