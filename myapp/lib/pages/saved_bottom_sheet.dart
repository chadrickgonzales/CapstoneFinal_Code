import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;

Future<void> displayBottomSheet_saved(BuildContext context) async {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Color.fromARGB(225, 41, 42, 60),
    isScrollControlled: true,
    builder: (context) {
      return SavedBottomSheet();
    },
  );
}

class SavedBottomSheet extends StatefulWidget {
  @override
  _SavedBottomSheetState createState() => _SavedBottomSheetState();
}

class _SavedBottomSheetState extends State<SavedBottomSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String googleApiKey = 'AIzaSyAocNg3WkX5ppmhc-vTf1IHvG75EM1Rr5k'; // Replace with your Google API Key

  bool _showDetails = false;
  Map<String, dynamic>? _selectedPlaceDetails;

  Future<List<Map<String, dynamic>>> _fetchSavedPlacesWithDetails() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final currentUserId = currentUser?.uid;

  if (currentUserId == null) {
    print("User is not logged in.");
    return [];
  }

  try {
    final querySnapshot = await _firestore
        .collection('save')
        .where('userId', isEqualTo: currentUserId)
        .get();

    Set<String> uniquePlaceIds = Set();
    List<Map<String, dynamic>> uniqueSavedPlaces = [];

    for (var doc in querySnapshot.docs) {
      String? placeId = doc['placeId'] ?? doc['place_id']; 
      // Handle both field names
      final placeName = doc['placeName'] ?? 'Unknown Place';
      final docId = doc.id;
      final imageUrl = doc['imageUrl'] ?? 'no image';  // Get imageUrl directly from the 'save' collection

      if (!uniquePlaceIds.contains(placeId)) {
        uniquePlaceIds.add(placeId!);

        Map<String, dynamic>? placeDetails;
        try {
          placeDetails = await _fetchPlaceDetails(placeId);
        } catch (e) {
          print("Failed to fetch place details for $placeId: $e");
          placeDetails = {'name': placeName};
        }

        uniqueSavedPlaces.add({
          'docId': docId,
          'placeDetails': placeDetails,
          'placeName': placeName,
          'imageUrl': imageUrl, // Include imageUrl from 'save' collection
        });
      }
    }

    return uniqueSavedPlaces;
  } catch (e) {
    print("Error fetching saved places: $e");
    return [];
  }
}


  Future<Map<String, dynamic>> _fetchPlaceDetails(String place_id) async {
    final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$place_id&key=$googleApiKey'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['result'];
    } else {
      throw Exception('Failed to load place details');
    }
  }

  void _showPlaceDetails(Map<String, dynamic> placeDetails, {String? imageUrl}) {
  setState(() {
    _selectedPlaceDetails = {
      ...placeDetails,
      'imageUrl': imageUrl, // Add imageUrl to the place details
    };
    _showDetails = true;
  });
}

  void _hidePlaceDetails() {
    setState(() {
      _showDetails = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      widthFactor: 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0),
            child: Text(
              _showDetails ? 'Place Details' : 'Saved Places',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _showDetails
                ? PlaceDetailView(
                    placeDetails: _selectedPlaceDetails!,
                    onBack: _hidePlaceDetails,
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchSavedPlacesWithDetails(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'No saved places yet.',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final savedPlace = snapshot.data![index];
                          final placeDetails = savedPlace['placeDetails'];
                          final placeName = placeDetails['name'] ?? 'Unknown Place';
                          final address = placeDetails['formatted_address'] ?? 'Unknown Address';
                          final photoReference = placeDetails['photos']?[0]['photo_reference'];
                          final imageUrl = savedPlace['imageUrl']; // Use imageUrl from savedPlace // Handle photos
                          final docId = savedPlace['docId'];
                           return _buildSavedPlaceContainer(
                              placeName, address, photoReference, imageUrl, placeDetails, docId);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

Widget _buildSavedPlaceContainer(String placeName, String address,
    String? photoReference, String? imageUrl, Map<String, dynamic> placeDetails, String docId) {
  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return GestureDetector(
        onTap: () {
          _showPlaceDetails(placeDetails, imageUrl: imageUrl);
        },
        child: Container(
          height: 150.0,
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Stack(
            children: [
              // Display the base image if available
              if (imageUrl != null)
                Positioned.fill(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container();
                    },
                  ),
                ),
              // Display the photoReference image if available
              if (photoReference != null)
                Positioned.fill(
                  child: Image.network(
                    'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$googleApiKey',
                    fit: BoxFit.cover,
                    // Adjust opacity if needed
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (context, error, stackTrace) {
                      return Container();
                    },
                  ),
                ),
              // Text and bookmark icon
              Positioned(
                left: 8.0,
                bottom: 8.0,
                child: Row(
                  children: [
                    Icon(
                      Icons.place,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placeName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          address,
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8.0,
                bottom: 8.0,
                child: IconButton(
                  icon: Icon(
                    Icons.bookmark,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _toggleSavedState(docId, placeDetails['place_id'] ?? placeDetails['placeId']);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
  Future<void> _toggleSavedState(String docId, String placeId) async {
    final docRef = _firestore.collection('save').doc(docId);
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      await docRef.delete();
    } else {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await docRef.set({
          'userId': currentUser.uid,
          'placeId': placeId, // Ensure to store the placeId
          'placeName': 'Placeholder', // Provide real place name if necessary
        });
      }
    }
  }
}

class PlaceDetailView extends StatefulWidget {
  final Map<String, dynamic> placeDetails;
  final VoidCallback onBack;
  final String? imageUrl; // Add this line

  PlaceDetailView({required this.placeDetails, required this.onBack, this.imageUrl});

  @override
  _PlaceDetailViewState createState() => _PlaceDetailViewState();
}

class _PlaceDetailViewState extends State<PlaceDetailView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _commentController = TextEditingController();
  double _selectedRating = 0.0;

  Future<String?> _fetchUsername(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['username'] ?? 'Unknown User';
    } catch (e) {
      print("Failed to fetch username: $e");
      return 'Unknown User';
    }
  }

  Future<void> _submitReview() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final username = await _fetchUsername(currentUser.uid);
      final comment = _commentController.text.trim();
      final placeId = widget.placeDetails['place_id'] ?? widget.placeDetails['placeId']; // Handle both field names

      if (placeId != null && username != null && comment.isNotEmpty) {
        try {
          await _firestore.collection('ratings').add({
            'place_id': placeId,
            'placeId': placeId, // Ensure to store the placeId
            'username': username,
            'comment': comment,
            'rating': _selectedRating,
            'timestamp': FieldValue.serverTimestamp(),
          });

          _commentController.clear();
          setState(() {
            _selectedRating = 0.0;
          });
        } catch (e) {
          print("Failed to submit review: $e");
        }
      }
    }
  }

@override
Widget build(BuildContext context) {
  final placeName = widget.placeDetails['name'] ?? 'Unknown Place';
  final address = widget.placeDetails['formatted_address'] ?? 'Unknown Address';
  final photoReference = widget.placeDetails['photos']?[0]['photo_reference'];
 final imageUrl = widget.placeDetails['imageUrl'];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              placeName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: widget.onBack,
            ),
          ],
        ),
      ),
      if (photoReference != null)
       Positioned.fill(
                  child: Image.network(
                   'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=AIzaSyAocNg3WkX5ppmhc-vTf1IHvG75EM1Rr5k',
                    fit: BoxFit.cover,
                       height: 200,
                       width: 600,
                    errorBuilder: (context, error, stackTrace) {
                      return Container();
                    },
                  ),
                )
        
      else if (imageUrl != null) // Fallback to imageUrl if photoReference is not available
       Positioned.fill(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                       height: 200,
                       width: 600,
                    errorBuilder: (context, error, stackTrace) {
                      return Container();
                    },
                  ),
                ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          address,
          style: TextStyle(color: Colors.white70),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: RatingBar.builder(
          initialRating: _selectedRating,
          minRating: 1,
          itemCount: 5,
          itemBuilder: (context, index) => Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: (rating) {
            setState(() {
              _selectedRating = rating;
            });
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'Write your review...',
            hintStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          style: TextStyle(color: Colors.white),
          maxLines: 4,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _submitReview,
          child: Text('Submit Review'),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('ratings')
              //.where('place_id', isEqualTo: widget.placeDetails['place_id'])
              
               .where('placeId', isEqualTo: widget.placeDetails['placeId'])
                .where('place_id', isEqualTo: widget.placeDetails['place_id'])
                // google map api
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final reviews = snapshot.hasData ? snapshot.data!.docs : [];
            if (reviews.isEmpty) {
              return Center(
                child: Text(
                  'No reviews yet.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final review = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                  leading: Icon(Icons.person, color: Colors.white),
                  title: Text(
                    review['username'] ?? 'Unknown User',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    review['comment'] ?? '',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: Text(
                    '${review['rating']}⭐',
                    style: TextStyle(color: Colors.amber),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}
}
