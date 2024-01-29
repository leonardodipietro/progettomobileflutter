import 'package:progettomobileflutter/model/SpotifyTokenResponse.dart';
import 'package:dio/dio.dart';
import 'dart:convert'; // Per base64Encode
import 'package:progettomobileflutter/model/SpotifyModel.dart';

class SpotifyRepository {
  final Dio _dio = Dio();

  SpotifyRepository();

  Future<SpotifyTokenResponse> getToken(String code, String clientId, String clientSecret, String redirectUri) async {
    try {
      final response = await _dio.post(
        'https://accounts.spotify.com/api/token',
        options: Options(
          headers: <String, String>{
            'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
        ),
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'client_id': clientId,
          'client_secret': clientSecret
        },
      );

      if (response.statusCode == 200) {
        print("Risposta grezza: ${response.data}");
        var tokenResponse = SpotifyTokenResponse.fromJson(response.data);
        print("risposta duE :${tokenResponse}");
        return tokenResponse;
      } else {
        // Gestisci gli altri status code qui, se necessario
        throw Exception('Failed to get token: ${response.statusCode}');
      }
    } catch (e) {
      // Qui si catturano le eccezioni che possono verificarsi durante la chiamata API o la deserializzazione
      print("Errore: $e");
      throw Exception('Error getting token: $e');
    }
  }


  Future<List<Track>> getTopTracks(String accessToken, String timeRange, int limit) async {
    try {
      final response = await _dio.get(
        'https://api.spotify.com/v1/me/top/tracks',
        queryParameters: {
          'time_range': timeRange,
          'limit': limit
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken'
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['items'];
        return data.map((trackJson) => Track.fromJson(trackJson)).toList();
      } else {
        throw Exception('eerroe nelle toptrack: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('eerroe nelle toptrack: $e');
    }
  }

  Future<List<Artist>> getTopArtists(String accessToken, String timeRange, int limit) async {
    try {
      final response = await _dio.get(
        'https://api.spotify.com/v1/me/top/artists',
        queryParameters: {
          'time_range': timeRange,
          'limit': limit
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken'
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['items'];
        return data.map((trackJson) => Artist.fromJson(trackJson)).toList();
      } else {
        throw Exception('errore nel top artist ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errorre nel top artistss: $e');
    }
  }


}
