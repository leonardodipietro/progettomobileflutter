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

    }
  }

  String? get accessToken { //INUTILE?
    print("Token di Accesso: ${_spotifyTokenResponse?.accessToken}");
    return _spotifyTokenResponse?.accessToken;
  }

  Future<void> fetchTopTracks(String accessToken, String timeRange, int limit, Function(dynamic response, String timeRange) onTracksFetched) async {
    print('fetchTopTracks chiamato');
    if (accessToken == null) {
      print('Access Token is null');
      return;
    }
    try {
      final response = await _spotifyRepository.getTopTracks(accessToken, timeRange, limit);
      print("Contenuto risposta: $response");

      // Aggiorna lo stato appropriato tramite gli stream.
      switch (timeRange) {
        case "short_term":
          _shortTermTracksController.sink.add(response);
          break;
        case "medium_term":
          _mediumTermTracksController.sink.add(response);
          break;
        case "long_term":
          _longTermTracksController.sink.add(response);
          break;
        default:
          throw Exception('Time range non valido: $timeRange');
      }

      // Invoca il callback passando la risposta e il timeRange.
      onTracksFetched(response, timeRange);
    } catch (e) {
      print('Errore durante la fetchTopTracks: $e');

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
  Future<void> fetchTopArtists(String accessToken, String timeRange, int limit, Function(dynamic response, String timeRange) onArtistsFetched) async {
    print('fetchTopArtists chiamato');
    if (accessToken == null) {
      print('Access Token is null');
      return;
    }
    try {
      final response = await _spotifyRepository.getTopArtists(accessToken, timeRange, limit);
      print("Contenuto risposta: $response");

      // Aggiorna lo stato appropriato tramite gli stream.
      switch (timeRange) {
        case "short_term":
          _shortTermArtistsController.sink.add(response);
          break;
        case "medium_term":
          _mediumTermArtistsController.sink.add(response);
          break;
        case "long_term":
          _longTermArtistsController.sink.add(response);
          break;
        default:
          throw Exception('Time range non valido: $timeRange');
      }

      // Invoca il callback passando la risposta e il timeRange.
      onArtistsFetched(response, timeRange);
    } catch (e) {
      print('Errore durante la fetchTopArtists: $e');
    }
  }
}
