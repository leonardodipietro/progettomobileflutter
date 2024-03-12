class Recensione {
  final String commentId;
  final String userId;
  final String trackId;
  final String timestamp;
  final String content;
  final String artistId;

  Recensione({
    required this.commentId,
    required this.userId,
    required this.trackId,
    required this.timestamp,
    required this.content,
    required this.artistId,
  });

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'userId': userId,
      'trackId': trackId,
      'timestamp': timestamp,
      'content': content,
      'artistId': artistId,
    };
  }
  factory Recensione.fromMap(Map<dynamic, dynamic> map) {
    return Recensione(
      commentId: map['commentId'] as String,
      userId: map['userId'] as String,
      trackId: map['trackId'] as String,
      timestamp: map['timestamp'] as String,
      content: map['content'] as String,
      artistId: map['artistId'] as String,
    );
  }
}
