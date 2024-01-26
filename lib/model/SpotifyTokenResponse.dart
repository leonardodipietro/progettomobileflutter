class SpotifyTokenResponse {
  final String accessToken; // Token effettivo
  final String tokenType; // Con Spotify sarà sempre di tipo bearer
  final String scope; // Dati a cui puoi accedere con il token
  final int expiresIn; // Tempo di durata del token
  final String? refreshToken;

  SpotifyTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.scope,
    required this.expiresIn,
    this.refreshToken,
  });

  //prende i dati ottenuti dal json di risposta e li mette nell oggetto spotifytokenresponse
  factory SpotifyTokenResponse.fromJson(Map<String, dynamic> json) {
    return SpotifyTokenResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      scope: json['scope'],
      expiresIn: json['expires_in'],
      refreshToken: json['refresh_token'],
    );
  }

  // fa l opposto di quello sopra nel caso serva
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'scope': scope,
      'expires_in': expiresIn,
      'refresh_token': refreshToken,
    };
  }
}

