class Track {
  final String name;
  final Album album;
  final List<Artist> artists;
  final String id;

  Track({required this.name, required this.album, required this.artists, required this.id});
  factory Track.fromJson(Map<String, dynamic> json) {
    Album album;
    if (json.containsKey('album') && json['album'] is Map) {
      // Dati da Spotify
      album = Album.fromJson(json['album']);
    } else {
      print('Deserializzazione Track: $json');
      // Dati da Firebase
      String albumName = json['album'] ?? 'Nome Album mancante';
      String imageUrl = json['image_url'] ?? 'immagine mancante';
      album = Album(
        name: albumName,
        images: imageUrl.isNotEmpty ? [Image(url: imageUrl)] : [],
        releaseDate: json['release_date'] ?? 'Data di uscita mancante',
      );
    }

    List<Artist> artists = (json['artists'] as List).map((i) => Artist.fromJson(i)).toList();

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

    List<Image> imagesList = [];
    if (json.containsKey('images') && json['images'] is List) {
      // Caso per i dati di Spotify
      imagesList = json['images'].map<Image>((img) => Image.fromJson(img)).toList();
    } else if (json.containsKey('image_url') && json['image_url'] is String) {
      // Caso per i dati di Firebase con un singolo URL di immagine
      String imageUrl = json['image_url'];
      if (imageUrl.isNotEmpty) {
        imagesList.add(Image(url: imageUrl));
      }
    }

    List<String> genres = json['genres'] != null ? List<String>.from(json['genres'].map((genre) => genre.toString())) : [];
    print('Generi deserializzati: $genres');

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
      'images': images.isNotEmpty ? [{'url': images.first.url}] : [],
      'genres': genres,
    };
  }
}

class Image {
  final String url;

  Image({required this.url});

  factory Image.fromJson(Map<String, dynamic> json) {
    return Image(url: json['url']);
  }

}
