import 'package:flutter/material.dart';
import 'package:progettomobileflutter/model/SpotifyTokenResponse.dart';
import 'package:progettomobileflutter/api/SpotifyRepository.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart';
import 'dart:async';
class SpotifyViewModel with ChangeNotifier {
  final SpotifyRepository _spotifyRepository;
  final String _clientId;
  final String _clientSecret;
  final String _redirectUri;
  SpotifyTokenResponse? _spotifyTokenResponse;
  //broadcast serve a dire che piu parti possono ascoltare
  final StreamController<List<Track>> _shortTermTracksController = StreamController.broadcast();
  final StreamController<List<Track>> _mediumTermTracksController = StreamController.broadcast();
  final StreamController<List<Track>> _longTermTracksController = StreamController.broadcast();
  final StreamController<List<Track>> _topTracksController = StreamController.broadcast();
  final StreamController<Exception> _errorController = StreamController.broadcast();

  Stream<List<Track>> get shortTermTracksStream => _shortTermTracksController.stream;
  Stream<List<Track>> get mediumTermTracksStream => _mediumTermTracksController.stream;
  Stream<List<Track>> get longTermTracksStream => _longTermTracksController.stream;
  Stream<List<Track>> get topTracksStream => _topTracksController.stream;
  Stream<Exception> get errorsStream => _errorController.stream;


  final StreamController<List<Artist>> _shortTermArtistsController = StreamController.broadcast();
  final StreamController<List<Artist>> _mediumTermArtistsController = StreamController.broadcast();
  final StreamController<List<Artist>> _longTermArtistsController = StreamController.broadcast();
  final StreamController<List<Artist>> _topArtistsController = StreamController.broadcast();
  final StreamController<Exception> _errorControllerART = StreamController.broadcast();

  Stream<List<Artist>> get shortTermArtistsStream => _shortTermArtistsController.stream;
  Stream<List<Artist>> get mediumTermArtistsStream => _mediumTermArtistsController.stream;
  Stream<List<Artist>> get longTermArtistsStream => _longTermArtistsController.stream;
  Stream<List<Artist>> get topArtistsStream => _topArtistsController.stream;
  Stream<Exception> get errorsStreamART => _errorControllerART.stream;

  SpotifyViewModel(
      this._spotifyRepository,
      this._clientId,
      this._clientSecret,
      this._redirectUri,



      );

  SpotifyTokenResponse? get spotifyTokenResponse => _spotifyTokenResponse;
  //future è un oggetto che rappresenta un valore che sarà disponibile in futuro
  //usiamo la chiamata asincrona per evitare di bloccare l interfaccia utente mentre si esegue la chiamata
  Future<void> authenticate(String code) async {
    try {
//await sospende l esecuzione di autenticate finche non viene completata la chiamata api
      _spotifyTokenResponse = await _spotifyRepository.getToken(
          code,
          _clientId,
          _clientSecret,
          _redirectUri
      );

      notifyListeners();
    } catch (e) {
      // Gestisci l'errore
    }
  }

  String? get accessToken { //INUTILE?
    print("Token di Accesso: ${_spotifyTokenResponse?.accessToken}");
    return _spotifyTokenResponse?.accessToken;
  }

  Future<void> fetchTopTracks(String timeRange, int limit) async {
    print('fetchtoptracks chiamato');
    String? accessToken = _spotifyTokenResponse?.accessToken;
    if (accessToken == null) {
      throw Exception('Access Token is null');
    } else {
      try {
        final response = await _spotifyRepository.getTopTracks(accessToken, timeRange, limit);
        print ( "contenuto responde $response");
        // In base al timeRange, aggiorniamo lo stato appropriato.
        switch (timeRange) {
          case "short_term":
            print('Aggiornamento dello stream per short_term con: $response');
            _shortTermTracksController.sink.add(response);
            break;
          case "medium_term":
            print('Aggiornamento dello stream per short_term con: $response');
            _mediumTermTracksController.sink.add(response);
            break;
          case "long_term":
            _longTermTracksController.sink.add(response);
            break;
          default:
            throw Exception('Time range non valido: $timeRange');
        }
        // Aggiorna tutti i top tracks, se necessario
        _topTracksController.sink.add(response);


        print ( "vediamo se qui arriva $_topTracksController");
      } catch (e) {
        // Gestione degli errori
        print('Errore durante la fetchTopTracks: $e');
        _errorController.sink.add(e as Exception);
      }
    }
  }

  /*Future<List<Artist>> fetchTopArtists(String timeRange, int limit) async {
    String? accessToken = _spotifyTokenResponse?.accessToken;
    if (accessToken != null) {
      return await _spotifyRepository.getTopArtists(accessToken, timeRange, limit);
    } else {
      throw Exception('Access Token is null');
    }
  }
   */
  Future<void> fetchTopArtists(String timeRange, int limit) async {
    print('fetchtopartists chiamato');
    String? accessToken = _spotifyTokenResponse?.accessToken;
    if (accessToken == null) {
      throw Exception('Access Token is null');
    } else {
      try {
        final response = await _spotifyRepository.getTopArtists(accessToken, timeRange, limit);
        print ( "contenuto responde $response");
        // In base al timeRange, aggiorniamo lo stato appropriato.
        switch (timeRange) {
          case "short_term":
            print('Aggiornamento dello stream per short_term con: $response');
            _shortTermArtistsController.sink.add(response);
            break;
          case "medium_term":
            print('Aggiornamento dello stream per short_term con: $response');
            _mediumTermArtistsController.sink.add(response);
            break;
          case "long_term":
            _longTermArtistsController.sink.add(response);
            break;
          default:
            throw Exception('Time range non valido: $timeRange');
        }
        // Aggiorna tutti i top tracks, se necessario
        _topArtistsController.sink.add(response);


        print ( "vediamo se qui arriva $_topArtistsController");
      } catch (e) {
        // Gestione degli errori
        print('Errore durante la fetchTopTracks: $e');
        _errorControllerART.sink.add(e as Exception);
      }
    }
  }
}


// String? token = spotifyViewModel.accessToken; SE LO USO FUORI

// ESEMPIO DI USO DEL TOKEN QUI DENTRO PER DOPO
/*Future<void> fetchUserData() async {
    if (_spotifyTokenResponse?.accessToken == null) {
      // Gestire il caso in cui il token non sia disponibile
      return;
    }*/

/*String? get accessToken {
  print("Token di Accesso: ${_spotifyTokenResponse?.accessToken}");
  return _spotifyTokenResponse?.accessToken;*/