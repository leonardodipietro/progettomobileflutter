import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:progettomobileflutter/model/Recensione.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart' as Spotify;
import 'package:flutter/widgets.dart' as fw;
import 'package:progettomobileflutter/ViewModel/RecensioneViewModel.dart';
import 'package:progettomobileflutter/model/Recensione.dart';
import 'model/Utente.dart';


class BranoSelezionato extends StatefulWidget {
  final Spotify.Track track;
  //final Spotify.Artist artist;
  /*final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;*/


  const BranoSelezionato({Key? key, required this.track}) : super(key: key);

  @override
  _BranoSelezionatoState createState() => _BranoSelezionatoState();
}


class _BranoSelezionatoState extends State<BranoSelezionato> {

  final TextEditingController _controller = TextEditingController();
  Utente? utente;
  List<Recensione> _recensioni = [] ;
  final RecensioneViewModel _recensioneViewModel = RecensioneViewModel(); // Dichiarato qui


  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    //RecensioneViewModel _recensioneViewModel = RecensioneViewModel();
    _loadRecensioni();

  }
  void _loadRecensioni() {
    print("Pre-chiamata recensione");
    _recensioneViewModel.fetchRecensioniForTrack(widget.track.id, () {
      setState(() {
        _recensioni = List.from(_recensioneViewModel.recensioniList);
        print("Recensioni caricate: ${_recensioni.length}");
      });
    });
  }

  void _fetchCurrentUser() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      setState(() {
        utente = Utente.fromFirebaseUser(firebaseUser);
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
        title: Text(
            widget.track.name), // Mostra il nome della traccia come titolo
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Allinea gli elementi della riga in alto
              children: <Widget>[
                // Immagine dell'album
                widget.track.album.images.isNotEmpty
                    ? fw.Image.network(
                  widget.track.album.images[0].url,
                  height: 150,
                  width: 150, // Utilizza l'alias fw per Image di Flutter
                )
                    : Container(height: 150, width: 150, color: Colors.grey),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      InkWell(
                        onTap: () {

                          print("Testo cliccato");
                        },
                        child: Text(widget.track.artists.map((artist) => artist.name).join(", "),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,),
                      ),
                      SizedBox(height: 15), // Spaziatura verticale tra il nome dell'artista e il nome dell'album
                      Text(
                        widget.track.album.name,
                        style: TextStyle(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20), // Spaziatura verticale
            Text(
              'Recensioni:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _recensioni.length,
                itemBuilder: (context, index) {
                  final recensione = _recensioni[index];
                  return InkWell(
                    onLongPress: () {
                      // Mostra un AlertDialog quando l'elemento viene tenuto premuto
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Seleziona un'azione"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  title: Text('Modifica'),
                                  onTap: () {

                                    Navigator.of(context).pop(); // Chiudi il dialogo dopo il tap
                                  },
                                ),
                                ListTile(
                                  title: Text('Elimina'),
                                  onTap: () {
                                    _recensioneViewModel.deleteRecensione(recensione.commentId);
                                    Navigator.of(context).pop(); // Chiudi il dialogo dopo il tap
                                  },
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text("Annulla"),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: ListTile(
                      title: Text(recensione.content),
                      subtitle: Text("Scritta da: ${recensione.userId}"),
                    ),
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
                    hintText: 'Scrivi una recensione...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 10),
              // Aggiungi uno spazio tra il TextField e il bottone
              ElevatedButton(
                onPressed: () {
                  String commentContent = _controller.text;
                  // Qui va la logica per l'invio della recensione
                  print("siamo qui");
                  print("AAAAABBB ${utente?.userId}");
//e ${widget.track.id} e${commentContent} ");
                  if(commentContent.isNotEmpty){

                  _recensioneViewModel.saveRecensione(
                      utente?.userId, widget.track.id,commentContent, widget.track.artists.map((artist) => artist.id).join(", "));
                  };
                },
                child: Text('Invia'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      vertical: 20.0),
                ),
              ),
            ],
          ),


          ],
        ),
      ),
    );
  } //WIDGET BUILD
}
