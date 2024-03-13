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
  List<Track> _tracks=[];
  List<Recensione> _recensioni = [] ;
  final RecensioneViewModel _recensioneViewModel = RecensioneViewModel();
  @override
  void initState() {
    super.initState();
    _loadTracksReviewedByArtistDetails();
  }
  void _loadTracksReviewedByArtistDetails() {
    print("Pre-chiamata recensione");
    _recensioneViewModel.fetchTracksReviewedByArtistAndRetrieveDetails(widget.artist.id, (List<Track> tracks) {
      setState(() {
        // Assumendo che tu abbia definito una variabile _tracks nel tuo stato del widget
        // per tenere traccia delle tracce recensite recuperate e dei loro dettagli
        _tracks = tracks;
        print("Dettagli di tutte le tracce recensite recuperati: ${_tracks.length}");
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
            Expanded(

              child: ListView.builder(
                itemCount: _tracks.length,
                itemBuilder: (context, index) {
                  final track = _tracks[index];
                  return InkWell(
                    onTap: () {
                      print("Traccia selezionata: ${track.name}");
                    },
                    child: Container(
                      height: 120, // Fornisce una dimensione esplicita
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (track.album.images.isNotEmpty)
                              fw.Image.network(track.album.images[0].url, height: 100, width: 100)
                            else
                              Container(height: 100, width: 100, color: Colors.grey),
                            Text(
                              track.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )

            )
          ],
    ),
    ),
    );
  }


}
