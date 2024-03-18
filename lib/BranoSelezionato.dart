import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:progettomobileflutter/model/Recensione.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart' as Spotify;
import 'package:flutter/widgets.dart' as fw;
import 'package:progettomobileflutter/ViewModel/RecensioneViewModel.dart';
import 'model/Utente.dart';
import 'package:progettomobileflutter/ArtistaSelezionato.dart';
import 'package:progettomobileflutter/model/Risposta.dart';
import 'package:progettomobileflutter/ViewModel/RisposteViewModel.dart';

class BranoSelezionato extends StatefulWidget {
  final Spotify.Track track;

  //final Spotify.Artist artist;
  /*final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;*/

  const BranoSelezionato({super.key, required this.track});

  @override
  _BranoSelezionatoState createState() => _BranoSelezionatoState();
}

class _BranoSelezionatoState extends State<BranoSelezionato> {
  final TextEditingController _controller = TextEditingController();


  Spotify.Artist? artist;
  bool isLoading = true;
  Utente? actualuser;
  List<Recensione> _recensioni = [];
  List<Risposta> _risposte =[];
  final RecensioneViewModel _recensioneViewModel = RecensioneViewModel();
  final RisposteViewModel _risposteViewModel = RisposteViewModel();
  Map<String, Utente> usersMap = {};
  Map<String,Utente> usersMapRisp = {} ;
  //late Spotify.Artist artist;
  String? _replyingToCommentId;
  String _textFieldHint = 'Scrivi una recensione...'; // Valore di default
  String? _selectedCommentIdForReplies;
  //TextEditingController _editingController = TextEditingController();
  String? _editingCommentId; // Identificativo per la recensione che stai modificando,
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    //RecensioneViewModel _recensioneViewModel = RecensioneViewModel();
    _loadRecensioni();
    _fetchArtistDetails();
  }
  void _fetchArtistDetails() async {
    try {
      Spotify.Artist? artistDetails = await _recensioneViewModel.retrieveArtistById(widget.track.artists.first.id);
      if (artistDetails != null) {
        setState(() {
          artist = artistDetails;
          print("vediamo che succede ${artist?.name} artist?.name");
          isLoading = false; // Dati caricati, non più in caricamento
        });
      }
    } catch (error) {
      // Gestisci l'errore come preferisci
      print("Errore nel recupero dei dettagli dell'artista: $error");
    }
  }


  void _startReplyingToComment(String? commentId) {
    if (_replyingToCommentId == commentId) {
      // Se l'utente ripreme lo stesso bottone di risposta, considera come l'azione di annullamento della risposta
      setState(() {
        _replyingToCommentId = null;
        _textFieldHint =
            'Scrivi una recensione...'; // Reimposta al valore di default
      });
    } else {
      setState(() {
        _replyingToCommentId = commentId;
        _textFieldHint =
            'Scrivi un commento...'; // Cambia l'hint per la risposta
      });
    }

    // Opzionale: Sposta il focus sul campo di testo
    FocusScope.of(context).requestFocus(FocusNode());
  }
  void _fetchRispostePerRecensione(String commentIdFather) {
    _risposteViewModel.fetchCommentFromRecensione(commentIdFather).then((commentiList) {
      // Recupera gli ID utente dalle risposte
      List<String> userIds = commentiList.map((risposta) => risposta.userId).toList();
      // Assicurati che il tuo ViewModel abbia un metodo fetchUsers che accetta una lista di userIds
      _risposteViewModel.fetchUsers(userIds).then((usersMap) {
        setState(() {
          _risposte = commentiList;
          usersMapRisp = usersMap; // Aggiorna la mappa degli utenti con i nuovi dati
        });
      });
    }).catchError((error) {
      print("Errore nel recuperare i dati: $error");
    });
  }
  void _updateRisposte(String commentIdFather) {
    _risposteViewModel.fetchCommentFromRecensione(commentIdFather).then((commentiList) {
      // Ottieni gli ID utente dalle nuove risposte
      List<String> userIds = commentiList.map((risposta) => risposta.userId).toSet().toList();

      // Recupera e aggiorna i dettagli degli utenti
      _risposteViewModel.fetchUsers(userIds).then((usersMap) {
        setState(() {
          // Aggiorna la lista delle risposte e la mappa degli utenti
          _risposte = commentiList;
          usersMapRisp.addAll(usersMap); // Aggiorna o sovrascrivi la mappa degli utenti
        });
      });
    });
  }




  void _loadRecensioni() {
    print("Pre-chiamata recensione");
    _recensioneViewModel.fetchRecensioniForTrack(widget.track.id, () {
      setState(() {
        _recensioni = List.from(_recensioneViewModel.recensioniList);
        print("Recensioni caricate: ${_recensioni.length}");
      });

      final userIds =
          _recensioni.map((recensione) => recensione.userId).toSet().toList();
      _recensioneViewModel
          .fetchUsers(userIds)
          .then((Map<String, Utente> newUsersMap) {
        setState(() {
          usersMap = newUsersMap;
        });
      });
    });
  }

  void _fetchCurrentUser() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      setState(() {
        actualuser = Utente.fromFirebaseUser(firebaseUser);
        print("MI SERVE ${actualuser?.userId}");
      });
    }
  }

  @override
  void dispose() {
    // Pulisce il controller quando il widget viene rimosso dall'albero dei widget.
    _controller.dispose();
    super.dispose();
  }

  /* void _navigateToArtistaSelezionato(Spotify.Artist artist)  {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ArtistaSelezionato(artist: artist )),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.track.name), // Mostra il nome della traccia come titolo
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Allinea gli elementi della riga in alto
              children: <Widget>[
                // Immagine dell'album
                widget.track.album.images.isNotEmpty
                    ? fw.Image.network(
                        widget.track.album.images[0].url,
                        height: 150,
                        width: 150, // Utilizza l'alias fw per Image di Flutter
                      )
                    : Container(height: 150, width: 150, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          _recensioneViewModel
                              .retrieveArtistById(widget.track.artists.first.id)
                              .then((artist) {
                                print("PROVIAMO ${widget.track.artists.first.name}");
                            if (artist != null) {
                              _navigateToArtistaSelezionato(artist);
                              print("vediamo SE c è AAA ${artist.name}");
                            } else {
                              print("nessun artista trovato");
                              // Gestisci il caso in cui l'artista non è stato trovato o c'è stato un errore
                            }
                          });
                        },
                        child: Text(
                            //widget.track.artists.first.name
                              artist?.name ?? 'Caricamento artista...',
                             // .join(", "),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Spaziatura verticale tra il nome dell'artista e il nome dell'album
                      Text(
                        widget.track.album.name,
                        style: const TextStyle(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Spaziatura verticale
            const Text(
              'Recensioni:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _recensioni.length,
                itemBuilder: (context, index) {
                  final recensione = _recensioni[index];
                  final utente = usersMap[recensione.userId];
                  bool mostraRisposte = _selectedCommentIdForReplies == recensione.commentId;

                  return Column(
                    children: [
                      InkWell(
                        onLongPress: () {
                          if (recensione.userId == actualuser?.userId) {
                             showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Seleziona un'azione"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      title: const Text('Modifica'),
                                      onTap: () {
                                        Navigator.of(context).pop();// Chiudi il dialogo dopo il tapù
                                        setState(() {
                                          _controller.text = recensione.content; // Imposta il testo della recensione nella TextField
                                          _editingCommentId = recensione.commentId; // Salva l'ID della recensione che stai modificando
                                          _textFieldHint = 'Modifica la tua recensione...'; // Opzionale: aggiorna l'hint della TextField
                                        });
                                      },
                                    ),
                                    ListTile(
                                      title: const Text('Elimina'),
                                      onTap: () {
                                        _recensioneViewModel.deleteRecensione(recensione.commentId);
                                        _recensioneViewModel.deleteRecensioneFromUser(recensione.commentId, recensione.userId);
                                        Navigator.of(context).pop(); // Chiudi il dialogo dopo il tap
                                      },
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text("Annulla"),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              );
                            },
                          );
                          }//QUI
                        },
                        child: ListTile(
                          leading: utente?.profile_image != null
                              ? Image.network(
                            utente!.profile_image!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                              : const CircleAvatar(
                                backgroundColor: Colors.white10,
                                child: Icon(Icons.account_circle, color: Colors.white),
                          ),
                          title: Text(recensione.content),
                          subtitle: Text("Scritta da: ${utente?.name ?? 'Utente sconosciuto'}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.reply),
                            onPressed: () {
                              _startReplyingToComment(recensione.commentId);
                              if (!mostraRisposte) {
                                _fetchRispostePerRecensione(recensione.commentId);
                              }
                              setState(() {
                                _selectedCommentIdForReplies = mostraRisposte ? null : recensione.commentId;
                              });
                            },
                          ),
                        ),
                      ),
                      if (mostraRisposte)
                        FutureBuilder<List<Risposta>>(
                          future: _risposteViewModel.fetchCommentFromRecensione(recensione.commentId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text("Errore nel caricamento delle risposte: ${snapshot.error}");
                            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, rispostaIndex) {
                                    final risposta = snapshot.data![rispostaIndex];
                                    final utenteRisposta =  usersMapRisp[risposta.userId];
                                    print("prova qui $utenteRisposta") ;
                                    return ListTile(
                                      title: Text(risposta.answercontent),
                                      subtitle: Text("Risposta di: ${utenteRisposta?.name ?? 'Utente sconosciuto'}"),
                                      leading: utenteRisposta?.profile_image != null
                                          ? Image.network(
                                        utenteRisposta!.profile_image!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                          : const CircleAvatar(
                                        backgroundColor: Colors.white10,
                                        child: Icon(Icons.account_circle, color: Colors.white),
                                      ),
                                      onLongPress: () {
                                        if (risposta.userId == actualuser?.userId) {
                                        // Mostra un AlertDialog quando l'utente mantiene premuta una risposta
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                  title: Text("Vuoi cancellare questa risposta?"),
                                                  actions: <Widget>[
                                                    TextButton(
                                                        child: Text("Annulla"),
                                                        onPressed: () {
                                                         Navigator.of(context).pop(); // Chiudi il dialogo
                                                         },
                                                      ),
                                                    TextButton(
                                                       child: Text("Elimina"),
                                                       onPressed: () {
                                                       // Chiama il metodo per cancellare la risposta
                                                        _risposteViewModel.deleteRisposta(risposta.answerId);
                                                       Navigator.of(context).pop(); // Chiudi il dialogo

                                                       },
                                                    ),
                                                    ],
                                              );
                                            },
                                        );
                                        }  //qui
                                    }

                                    );
                                  },
                                ),
                              );
                            } else {
                              return const Text("Nessuna risposta trovata.");
                            }
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _textFieldHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Aggiungi uno spazio tra il TextField e il bottone
                ElevatedButton(
                  onPressed: () {
                    String content = _controller.text.trim();
                    if (content.isNotEmpty) {
                      if (_replyingToCommentId != null) {
                        String commentIdFather = _replyingToCommentId ?? "";
                        // Modalità risposta a un commento (utilizza `saveRisposta`)
                        _risposteViewModel.saveRisposta(
                          actualuser?.userId ?? "",
                          _replyingToCommentId!,
                          content,
                        ).then((_) {
                          // Chiamata alla funzione di aggiornamento dopo il successo
                          _updateRisposte(commentIdFather);
                          _replyingToCommentId = null; // Resetta l'ID della risposta dopo l'invio
                        });
                        _replyingToCommentId = null; // Resetta l'ID della risposta dopo l'invio
                      } else if (_editingCommentId != null) {
                        // Modalità modifica recensione (utilizza `updateRecensione`)
                        _recensioneViewModel.updateRecensione(
                          _editingCommentId!,
                          actualuser?.userId ?? "",
                          widget.track.id,
                          content,
                          widget.track.artists.map((artist) => artist.id).join(", "),
                        );
                        _editingCommentId = null; // Resetta l'ID della recensione in modifica dopo l'invio
                      }  else {
                        // Modalità recensione (utilizza il metodo esistente `saveRecensione`)
                        _recensioneViewModel.saveRecensione(
                          actualuser?.userId ?? "",
                          widget.track.id,
                          content,
                          widget.track.artists.map((artist) => artist.id).join(", "),
                        );
                      }

                      _controller.clear(); // Pulisci il campo di testo dopo l'invio
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                  ),
                  child: const Text('Invia'),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  } //WIDGET BUILD

  void _navigateToArtistaSelezionato(Spotify.Artist artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ArtistaSelezionato(artist: artist)),
    );
  }

  Future<Map<String, dynamic>?> fetchUserData(String userId) async {
    try {
      DatabaseReference reference =
          FirebaseDatabase.instance.reference().child('users').child(userId);
      DataSnapshot snapshot = (await reference.once()).snapshot;
      Map<dynamic, dynamic>? userData =
          snapshot.value as Map<dynamic, dynamic>?;

      return userData?.cast<String, dynamic>(); // Cast a <String, dynamic>
    } catch (e) {
      print('Errore durante il recupero dei dati dell\'utente: $e');
      return null; // Gestisci l'errore in modo appropriato
    }
  }
}
