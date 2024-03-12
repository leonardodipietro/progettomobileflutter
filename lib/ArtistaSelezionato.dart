import 'package:progettomobileflutter/ViewModel/RecensioneViewModel.dart';
import 'package:progettomobileflutter/model/Recensione.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart' as Spotify;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as fw;

class ArtistaSelezionato extends StatefulWidget {
  final Spotify.Artist artist;

  const ArtistaSelezionato({Key? key, required this.artist}) : super(key: key);

  @override
  _ArtistaSelezionatoState createState() => _ArtistaSelezionatoState();
}

class _ArtistaSelezionatoState extends State<ArtistaSelezionato> {

  List<Recensione> _recensioni = [] ;
  final RecensioneViewModel _recensioneViewModel = RecensioneViewModel();
  @override
  void initState() {
    super.initState();
    _loadRecensioniforArtist();
  }
  void _loadRecensioniforArtist() {
    print("Pre-chiamata recensione");
    _recensioneViewModel.fetchRecensioniForArtist(widget.artist.id, () {
      setState(() {
        _recensioni = List.from(_recensioneViewModel.recensioniList);
        print("Recensioni caricate: ${_recensioni.length}");
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.artist.name), // Mostra il nome dell'artista come titolo
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          // Centra i widget nella colonna
          children: <Widget>[
            widget.artist.images.isNotEmpty
                ? fw.Image.network(
                    widget.artist.images[0].url,
                    height: 200,
                    width: 200, // Utilizza l'alias fw per Image di Flutter
                  )
                : Container(height: 250, width: 250, color: Colors.grey),
            SizedBox(height: 50),
            Text(
              "recensioni",
              textAlign: TextAlign.center,
            ),
            /*RIFARE DOPOExpanded(

              child: ListView.builder(
                itemCount: _recensioni.length,
                itemBuilder: (context, index) {
                  final recensione = _recensioni[index];

                }
            )
            )
*/

          ],
        ),
      ),
    );
  }


}
