class Track {
  final String name;
  final Album album;
  final List<Artist> artists;
  final String id;

  Track({required this.name, required this.album, required this.artists, required this.id});

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      name: json['name'],
      album: Album.fromJson(json['album']),
      artists: (json['artists'] as List).map((i) => Artist.fromJson(i)).toList(),
      id: json['id'],
    );
  }
}
class Album {
  final String name;
  final List<Image> images;
  final String releaseDate;

  Album({required this.name, required this.images, required this.releaseDate});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      name: json['name'],
      images: (json['images'] as List).map((i) => Image.fromJson(i)).toList(),
      releaseDate: json['release_date'],
    );
  }
}
class Artist {
  final String name;
  final String id;
  final String imageUrl;
  final List<String> genres;

  Artist({
    required this.name,
    required this.id,
    required this.imageUrl,
    required this.genres,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {

    var imageUrl = json['images'] != null && (json['images'] as List).isNotEmpty
        ? (json['images'] as List)[0]['url']
        : ''; // Prende l'URL della prima immagine, se ci sta

    // Casting esplicito di ogni elemento della lista da dynamic a String
    List<String> genres = [];
    if (json['genres'] != null) {
      genres = List<String>.from(json['genres'].map((genre) => genre.toString()));
    } //  probabilmente sarà sbagliato

    return Artist(
      name: json['name'],
      id: json['id'],
      imageUrl: imageUrl,
      genres: genres,
    );
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
