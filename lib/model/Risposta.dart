class Risposta {
  final String commentIdfather;
  final String answerId; // Unique ID for the answer
  final String userId;   // ID of the user who answered
  final String timestamp; // Timestamp of when the review was left
  final String answercontent;

  Risposta({
    this.commentIdfather = "",
    this.answerId = "",
    this.userId = "",
    this.timestamp = "",
    this.answercontent = "",
  });

  // Converts object into a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'commentIdfather': commentIdfather,
      'answerId': answerId,
      'userId': userId,
      'timestamp': timestamp,
      'answercontent': answercontent,
    };
  }

  // Factory constructor to create a Risposta from a map
  factory Risposta.fromMap(Map<dynamic, dynamic> map) {
    return Risposta(
      commentIdfather: map['commentIdfather'] ?? "",
      answerId: map['answerId'] ?? "",
      userId: map['userId'] ?? "",
      timestamp: map['timestamp'] ?? "",
      answercontent: map['answercontent'] ?? "",
    );
  }
}