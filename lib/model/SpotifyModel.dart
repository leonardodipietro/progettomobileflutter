class Track {
  final String name;
  final Album album;
  final List<Artist> artists;
  final String id;

  Track({required this.name, required this.album, required this.artists, required this.id});

  factory Track.fromJson(Map<String, dynamic> json) {
    print('Deserializzazione Track: $json');
    var albumJson = json['album'];
    Album album;
    if (albumJson is Map<String, dynamic>) {
      album = Album.fromJson(albumJson);
    } else {
      album = Album(name: '', images: [], releaseDate: '');
    }

    List<Artist> artists = (json['artists'] as List).map((i) => Artist.fromJson(i)).toList();
    print('Artisti deserializzati: ${artists.map((a) => a.name)}');

    return Track(
      name: json['name'] ?? 'Nome mancante',
      album: album,
      artists: artists,
      id: json['id'] ?? 'ID mancante',
    );
  }
}

class Album {
  final String name;
  final List<Image> images;
  final String releaseDate;

  Album({required this.name, required this.images, required this.releaseDate});
  factory Album.fromJson(Map<String, dynamic> json) {
    print('Deserializzazione Album: $json');
    return Album(
      name: json['name'] ?? 'Nome Album mancante',
      images: (json['images'] as List).map((i) => Image.fromJson(i)).toList(),
      releaseDate: json['release_date'] ?? 'Data di uscita mancante',
    );
  }
}

class Artist {
  final String name;
  final String id;
  final List<Image> images;
  final List<String> genres;

  Artist({
    required this.name,
    required this.id,
    required this.images,
    required this.genres,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    print('Deserializzazione Artist: $json');
    var imageUrl = json['images'] != null && (json['images'] as List).isNotEmpty
        ? (json['images'] as List)[0]['url']
        : '';

    List<String> genres = json['genres'] != null ? List<String>.from(json['genres'].map((genre) => genre.toString())) : [];
    print('Generi deserializzati: $genres');

    List<Image> imagesList = imageUrl.isNotEmpty ? [Image(url: imageUrl)] : [];
    return Artist(
      name: json['name'] ?? 'Nome Artista mancante',
      id: json['id'] ?? 'ID Artista mancante',
      images: imagesList,
      genres: genres,
    );
  }



  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'images': images.isNotEmpty ? [{'url': images.first.url}] : [], // Assumendo che vuoi solo l'URL della prima immagine
      'genres': genres,
    };
  }

}

class Image {
  final String url;

  Image({required this.url});

  factory Image.fromJson(Map<String, dynamic> json) {
    return Image(
      url: json['url'],
    );
  }
}