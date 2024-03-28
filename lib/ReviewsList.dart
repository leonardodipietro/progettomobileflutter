import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Track {
  final String id;
  final String name;
  final List<String> artistIds;
  final String albumName;
  final String imageUrl;
  List<String> artistNames;

  Track({
    required this.id,
    required this.name,
    required this.artistIds,
    required this.albumName,
    required this.imageUrl,
    List<String> artistNames = const[],
  }) : artistNames = artistNames;
}

class Review {
  final String artistId;
  final String commentId;
  final String content;
  final String timestamp;
  final String trackId;
  final String userId;
  Track track;

  Review({
    required this.artistId,
    required this.commentId,
    required this.content,
    required this.timestamp,
    required this.trackId,
    required this.userId,
    required this.track,
  });

  void setTrack(Track newTrack){
    track = newTrack;
  }
}

class ReviewsList extends StatefulWidget {
  @override
  _ReviewsListState createState() => _ReviewsListState();
}

class _ReviewsListState extends State<ReviewsList> {
  late List<Review> reviews = [];

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  void fetchReviews() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userReviewsRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('reviews');
      try {
        DataSnapshot userReviewsSnapshot =
        await userReviewsRef.once().then((event) => event.snapshot);
        if (userReviewsSnapshot.value != null &&
            userReviewsSnapshot.value is Map<dynamic, dynamic>) {
          List<String> reviewIds = [];
          (userReviewsSnapshot.value as Map<dynamic, dynamic>)
              .forEach((key, value) {
            if (value is String) {
              reviewIds.add(value);
            }
          });
          await fetchReviewsData(reviewIds);
        }
      } catch (error) {
        print('Errore durante il recupero delle recensioni: $error');
      }
    }
  }

  Future<void> fetchReviewsData(List<String> reviewIds) async {
    List<Review> fetchedReviews = [];
    for (String reviewId in reviewIds) {
      DatabaseReference reviewRef = FirebaseDatabase.instance
          .ref()
          .child('reviews')
          .child(reviewId);
      try {
        DataSnapshot reviewSnapshot =
        await reviewRef.once().then((event) => event.snapshot);
        if (reviewSnapshot.value != null && reviewSnapshot.value is Map) {
          Map<dynamic, dynamic>? reviewData =
          reviewSnapshot.value as Map<dynamic, dynamic>?;
          if (reviewData != null) {
            Review review = Review(
              artistId: reviewData['artistId'] ?? '',
              commentId: reviewId,
              content: reviewData['content'] ?? '',
              timestamp: reviewData['timestamp'] ?? '',
              trackId: reviewData['trackId'] ?? '',
              userId: reviewData['userId'] ?? '',
              track: Track(
                id: '',
                name: '',
                artistIds: [],
                albumName: '',
                imageUrl: '',
              ),
            );
            fetchedReviews.add(review);
          }
        }
      } catch (error) {
        print(
            'Errore durante il recupero delle informazioni della recensione: $error');
      }
    }
    await fetchTracksInfo(fetchedReviews);
  }

  Future<void> fetchTracksInfo(List<Review> fetchedReviews) async {
    for (var review in fetchedReviews) {
      DatabaseReference trackRef = FirebaseDatabase.instance
          .ref()
          .child('tracks')
          .child(review.trackId);
      try {
        DataSnapshot trackSnapshot =
        await trackRef.once().then((event) => event.snapshot);
        if (trackSnapshot.value != null && trackSnapshot.value is Map) {
          Map<dynamic, dynamic>? trackData =
          trackSnapshot.value as Map<dynamic, dynamic>?;
          if (trackData != null) {
            List<String> artistIds = [];
            for (var artistId in trackData['artists']) {
              artistIds.add(artistId);
            }
            Track track = Track(
              id: review.trackId,
              name: trackData['name'] ?? '',
              artistIds: artistIds,
              albumName: trackData['album'] ?? '',
              imageUrl: trackData['image_url'] ?? '',
            );
            review.track = track;


            List<String> artistNames =
            await fetchArtistNames(track.artistIds);
            review.track.artistNames =
                artistNames;
          }
        }
      } catch (error) {
        print(
            'Errore durante il recupero delle informazioni sulla traccia: $error');
      }
    }
    setState(() {
      reviews = fetchedReviews;
    });
  }

  Future<List<String>> fetchArtistNames(List<String> artistIds) async {
    List<String> artistNames = [];
    for (String artistId in artistIds) {
      DatabaseReference artistRef =
      FirebaseDatabase.instance.ref().child('artists').child(artistId);
      try {
        DataSnapshot artistSnapshot =
        await artistRef.once().then((event) => event.snapshot);
        if (artistSnapshot.value != null &&
            artistSnapshot.value is Map<dynamic, dynamic>) {
          Map<dynamic, dynamic>? artistData =
          artistSnapshot.value as Map<dynamic, dynamic>?;
          if (artistData != null) {
            String artistName = artistData['name'] ?? '';
            artistNames.add(artistName);
          }
        }
      } catch (error) {
        print(
            'Errore durante il recupero delle informazioni dell\'artista: $error');
      }
    }
    return artistNames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recensioni'),
      ),
      body: reviews.isEmpty
      ? Center(
    child: reviews.isNotEmpty
        ? CircularProgressIndicator()
        : FutureBuilder(
      future: Future.delayed(Duration(seconds: 10)),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          return Text(
              "Non hai ancora scritto nessuna recensione");
        }
      },
    ),
  )
      : ListView.separated(
        itemCount: reviews.length,
        separatorBuilder: (BuildContext context, int index) {
          return Divider(
            color: Colors.grey,
            height: 1,
          );
        },
        itemBuilder: (context, index) {
          final review = reviews[index];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: review.track.imageUrl.isNotEmpty
                            ? Image.network(
                          review.track.imageUrl,
                          width: 50,
                          height: 50,
                        )
                            : Icon(Icons.library_music),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.track.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Artista: ${review.track.artistNames.join(", ")}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Album: ${review.track.albumName}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  review.content,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Container()),
                    Text(
                      review.timestamp,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}