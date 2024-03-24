import 'package:progettomobileflutter/ViewModel/RecensioneViewModel.dart';
import 'package:progettomobileflutter/model/Recensione.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart' as Spotify;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as fw;
import 'package:progettomobileflutter/BranoSelezionato.dart';

class ArtistaSelezionato extends StatefulWidget {
  final Spotify.Artist artist;

  const ArtistaSelezionato({super.key, required this.artist});

  @override
  _ArtistaSelezionatoState createState() => _ArtistaSelezionatoState();
}

class _ArtistaSelezionatoState extends State<ArtistaSelezionato> {
  List<Track> _tracks=[];
  final List<Recensione> _recensioni = [] ;
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
              height: 150,
              width: 150, // Utilizza l'alias fw per Image di Flutter
              errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                  ) {
                // In caso di errore nel caricamento dell'immagine (ad es., mancanza di connessione),
                // mostra l'immagine di default con la decorazione.
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Assicura contrasto con l'immagine scura
                    borderRadius: BorderRadius.circular(8), // Angoli arrotondati
                  ),
                  child: fw.Image.asset(
                    'assets/images/iconacantante.jpg',
                    height: 150,
                    width: 150,
                  ),
                );
              },
            )
                : Container(
              decoration: BoxDecoration(
                color: Colors.white, // Assicura contrasto con l'immagine scura
                borderRadius: BorderRadius.circular(8), // Angoli arrotondati
              ),
              child: fw.Image.asset(
                'assets/images/iconacantante.jpg',
                height: 150,
                width: 150,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "recensioni",
              style: TextStyle(fontSize: 30),
            ),
            Expanded(

                child: ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return InkWell(
                      onTap: () {
                        print("Traccia selezionata: ${track.name}");
                        _navigateToBranoSelezionato(track);
                      },
                      child: SizedBox(
                        height: 120, // Fornisce una dimensione esplicita
                        child: Row( // Usa Row invece di Column
                          children: [
                            // Immagine a sinistra
                            if (track.album.images.isNotEmpty)
                              fw.Image.network(track.album.images[0].url, height: 80, width: 80)
                            else
                              Container(height: 100, width: 100, color: Colors.grey),
                            const SizedBox(width: 10), // Aggiunge spazio tra l'immagine e il testo
                            // Testo (nome del brano) a destra
                            Expanded( // Usa Expanded per far sì che il testo occupi lo spazio rimanente
                              child: Text(
                                track.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle( fontSize: 20
                                  // Aggiungi qui eventuali stili per il testo
                                ),
                              ),
                            ),
                          ],
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

  void _navigateToBranoSelezionato(Spotify.Track track) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BranoSelezionato(track: track )),
    );
  }


}
