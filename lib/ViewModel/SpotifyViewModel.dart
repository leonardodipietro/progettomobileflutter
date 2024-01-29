import 'package:flutter/material.dart';
import 'package:progettomobileflutter/model/SpotifyTokenResponse.dart';
import 'package:progettomobileflutter/api/SpotifyRepository.dart';
import 'package:progettomobileflutter/model/SpotifyModel.dart';

class SpotifyViewModel with ChangeNotifier {
  final SpotifyRepository _spotifyRepository;
  final String _clientId;
  final String _clientSecret;
  final String _redirectUri;
  SpotifyTokenResponse? _spotifyTokenResponse;

  SpotifyViewModel(
      this._spotifyRepository,
      this._clientId,
      this._clientSecret,
      this._redirectUri
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

  Future<List<Track>> fetchTopTracks(String timeRange, int limit) async {
    String? accessToken = _spotifyTokenResponse?.accessToken;
    if (accessToken != null) {
      return await _spotifyRepository.getTopTracks(accessToken, timeRange, limit);
    } else {
      throw Exception('Access Token is null');
    }
  }

  Future<List<Artist>> fetchTopArtists(String timeRange, int limit) async {
    String? accessToken = _spotifyTokenResponse?.accessToken;
    if (accessToken != null) {
      return await _spotifyRepository.getTopArtists(accessToken, timeRange, limit);
    } else {
      throw Exception('Access Token is null');
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