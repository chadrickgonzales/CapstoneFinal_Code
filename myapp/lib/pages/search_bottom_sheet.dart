import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;

Future<void> displayBottomSheet_search(BuildContext context) async {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Color.fromARGB(225, 41, 42, 60),
    isScrollControlled: true,
    builder: (context) {
      return SearchBottomSheet(); // Updated to use SearchBottomSheet
    },
  );
}

class SearchBottomSheet extends StatefulWidget {
  @override
  _SearchBottomSheetState createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  double _bottomInset = 0.0;
  String _searchQuery = '';
  List<dynamic> _places = [];
  Map<String, dynamic>? _selectedPlace; // State to manage selected place
  bool _showDetails =
      false; // State to toggle between search results and details view
  String _selectedCategory = ''; // State to track selected category

  TextEditingController commentTextController = TextEditingController();
  double selectedRating = 0.0; // Initialize with your default rating

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _focusNode.addListener(_updateFocusState);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    _focusNode.removeListener(_updateFocusState);
    _focusNode.dispose();
    super.dispose();
  }

  void _updateFocusState() {
    setState(() {});
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance!.window.viewInsets.bottom;
    setState(() {
      _bottomInset = bottomInset;
      if (bottomInset == 0) {
        // Clear suggestions when keyboard is closed
        _places.clear();
      }
    });
  }

  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _places.clear();
      });
      return;
    }

    final apiKey = 'AIzaSyANC6OfmrgsOcypf8rHrKaVCvvS89kQRMM';
    final googlePlacesUrl =
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$apiKey';
    final response = await http.get(Uri.parse(googlePlacesUrl));

    if (response.statusCode == 200) {
      List<dynamic> googleResults = json.decode(response.body)['results'];

      List<dynamic> firestoreResults = await _fetchFirestorePlaces(query);

      List<dynamic> combinedResults = [...googleResults, ...firestoreResults];

      setState(() {
        _places = combinedResults;
      });
    } else {
      throw Exception('Failed to load places');
    }
  }

  String? _getPhotoUrl(String? photoReference) {
    if (photoReference == null) return null;
    final apiKey =
        'AIzaSyANC6OfmrgsOcypf8rHrKaVCvvS89kQRMM'; // Replace with your Google Maps API key
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';
  }

  Future<Map<String, dynamic>> _fetchPlaceDetails(
      String placeId, String placeName) async {
    Map<String, dynamic> placeDetails = {};

    if (placeId.isNotEmpty) {
      // Fetch Google Maps API details
      const String apiKey = 'AIzaSyANC6OfmrgsOcypf8rHrKaVCvvS89kQRMM';
      final String url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          placeDetails = data['result'];
        } else {
          print('Failed to fetch place details from Google Maps API');
        }
      } else {
        print('Failed to fetch place details from Google Maps API');
      }
    }

    // Fetch Firestore details based on the place name
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('place')
          .where('placeName', isEqualTo: placeName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic> firestoreData = querySnapshot.docs.first.data();
        placeDetails.addAll(firestoreData);
      } else {
        print('No documents found for place name: $placeName');
      }
    } catch (e) {
      print('Error fetching Firestore places: $e');
    }

    return placeDetails;
  }

  Future<List<dynamic>> _fetchFirestorePlaces(String query) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('place')
          .where('placeName', isEqualTo: query)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.map((doc) => doc.data()).toList();
      } else {
        print('No documents found for query: $query');
        return []; // Or handle empty case as needed
      }
    } catch (e) {
      print('Error fetching Firestore places: $e');
      throw e; // Optionally, re-throw the error to handle it elsewhere
    }
  }

  void _showPlaceDetails(Map<String, dynamic> place) async {
    setState(() {
      _selectedPlace = place;
      _showDetails = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;

    if (userId != null && _selectedPlace != null) {
      final placeId =
          _selectedPlace!['place_id'] ?? _selectedPlace!['placeId'] ?? '';
      final placeName =
          _selectedPlace!['name'] ?? _selectedPlace!['placeName'] ?? '';
      final types = _selectedPlace!['types'];

      String? category;

      // Fetch category from Firestore collection if it exists
      try {
        final firestoreDoc = await FirebaseFirestore.instance
            .collection('place')
            .doc(placeId)
            .get();

        if (firestoreDoc.exists && firestoreDoc.data()?['category'] != null) {
          category = firestoreDoc.data()?['category'];
        } else {
          // Fallback to determining category based on place types if Firestore category is not available
          category = _determineCategory(types);
        }
      } catch (e) {
        print('Error fetching category from Firestore: $e');
        // Fallback to category determination if Firestore fetch fails
        category = _determineCategory(types);
      }

      // Fetch combined place details from Firestore and Google Places API
      try {
        final combinedPlaceDetails =
            await _fetchPlaceDetails(placeId, placeName);
        setState(() {
          _selectedPlace = combinedPlaceDetails;
        });
      } catch (e) {
        print('Error fetching place details: $e');
      }

      // Save to Firestore 'recent' collection
      try {
        await FirebaseFirestore.instance.collection('recent').add({
          'placeName': _selectedPlace!['name'] ?? _selectedPlace!['placeName'],
          'placeId': _selectedPlace!['place_id'] ?? _selectedPlace!['placeId'],
          'category': category,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'imageUrl': _selectedPlace!['imageUrl'] ?? '',
        });
      } catch (e) {
        print('Error saving to Firestore: $e');
      }
    }
  }

  String _determineCategory(List<dynamic>? types) {
    if (types != null && types is List<dynamic>) {
      if (_containsAny(types, [
        'tourist_attraction',
        'museum',
        'art_gallery',
        'historical sites',
        'landmarks',
        'park',
        'amusement_park',
        'aquarium',
        'zoo',
        'Sights',
      ])) {
        return 'Sights';
      } else if (_containsAny(types, ['park', 'natural_feature', 'Parks'])) {
        return 'Parks';
      } else if (_containsAny(types,
          ['train_station', 'bus_station', 'subway_station', 'Stations'])) {
        return 'Stations';
      } else if (_containsAny(
          types, ['restaurant', 'cafe', 'bakery', 'Food'])) {
        return 'Food';
      } else if (_containsAny(types, ['lodging', 'hotel', 'hostel', 'Hotel'])) {
        return 'Hotel';
      } else {
        return 'Other';
      }
    }
    return 'Unknown';
  }

  bool _containsAny(List<dynamic> list, List<String> values) {
    // Helper function to check if list contains any of the specified values
    for (var value in values) {
      if (list.contains(value)) {
        return true;
      }
    }
    return false;
  }

  void _goBackToSearch() {
    setState(() {
      _showDetails = false;
    });
  }

  Future<String?> _fetchUsername(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data()?['username'];
  }

  Future<List<DocumentSnapshot>> _fetchRecentPlaces(String category) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return []; // Return empty list if user is not authenticated
    }

    QuerySnapshot querySnapshot;
    if (category.isEmpty) {
      querySnapshot = await _firestore
          .collection('recent')
          .where('userId', isEqualTo: currentUser.uid)
          .get();
    } else {
      querySnapshot = await _firestore
          .collection('recent')
          .where('userId', isEqualTo: currentUser.uid)
          .where('category', isEqualTo: category)
          .get();
    }

    return querySnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.95,
      widthFactor: 1.0,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (_showDetails)
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _goBackToSearch,
                      ),
                    Text(
                      _showDetails ? 'Details' : 'Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_showDetails)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconButton(Icons.location_pin, 'Sights', () {
                        _filterByCategory('Sights');
                      }, 'Sights'),
                      _buildIconButton(Icons.park, 'Parks', () {
                        _filterByCategory('Parks');
                      }, 'Parks'),
                      _buildIconButton(Icons.train, 'Stations', () {
                        _filterByCategory('Stations');
                      }, 'Stations'),
                      _buildIconButton(Icons.restaurant, 'Food', () {
                        _filterByCategory('Food');
                      }, 'Food'),
                      _buildIconButton(Icons.hotel, 'Hotel', () {
                        _filterByCategory('Hotel');
                      }, 'Hotel'),
                    ],
                  ),
                ),
              SizedBox(height: 16.0),
              _showDetails
                  ? _buildPlaceDetails(_selectedPlace!)
                  : _buildSearchResults(),
            ],
          ),
          if (!_showDetails)
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom > 0
                  ? MediaQuery.of(context).viewInsets.bottom + 300.0
                  : 16.0,
              left: 16.0,
              right: 16.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add the Delete Recent Searches button here
                  ElevatedButton(
                    onPressed: () {
                      // No functionality, button is just for UI
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    ),
                    child: Text(
                      'Delete Recent Searches',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(
                      height:
                          8.0), // Space between the button and the text field
                  Container(
                    width: MediaQuery.of(context).size.width - 32.0,
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 193, 187, 191),
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(color: Colors.white),
                    ),
                    child: TextField(
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Looking for...',
                        hintStyle: TextStyle(color: Colors.white),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value ?? '';
                        });
                        if (_searchQuery.isNotEmpty) {
                          _searchPlaces(_searchQuery);
                        } else {
                          setState(() {
                            _places.clear();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom > 0
                ? MediaQuery.of(context).viewInsets.bottom + 16.0
                : 16.0,
            left: 16.0,
            right: 16.0,
            height: MediaQuery.of(context).size.height * 0.3,
            child: Visibility(
              visible: _searchQuery.isNotEmpty &&
                  _places.isNotEmpty &&
                  !_showDetails,
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(141, 138, 140, 0.8),
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(color: Colors.white),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _places.length,
                  itemBuilder: (context, index) {
                    final place = _places[index];
                    return ListTile(
                      //NAIBA ANG PART NA TOH
                      title: Text(
                        place['name'] ?? place['placeName'] ?? 'Unknown Place',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        place['formatted_address'] ??
                            place['placeId'] ??
                            'Unknown Location',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onTap: () => _showPlaceDetails(place),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      IconData icon, String label, VoidCallback onPressed, String category) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60.0,
          height: 60.0,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 40),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    bool _isBookmarked = false;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Container(); // Return an empty container if user is not authenticated
    }

    return FutureBuilder<List<DocumentSnapshot>>(
      future: _fetchRecentPlaces(_selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100.0,
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          );
        }

        final recentPlaces = snapshot.data ?? [];
        if (recentPlaces.isEmpty) {
          return Container(
            height: 100.0,
            alignment: Alignment.center,
            child: Text(
              'Search history is empty',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          );
        }

        // Use a Set to track unique placeIds
        Set<String> displayedPlaceIds = {};

        // Sort recent places by timestamp in descending order
        recentPlaces.sort((a, b) {
          Timestamp timestampA = a['timestamp'];
          Timestamp timestampB = b['timestamp'];
          return timestampB.compareTo(timestampA); // Sort in descending order
        });

        return Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            children: recentPlaces.map((doc) {
              final placeName = doc['placeName'];
              final placeId = doc['placeId'];
              final imageUrl = doc['imageUrl'] ?? '';

              if (displayedPlaceIds.contains(placeId)) {
                return Container();
              }

              displayedPlaceIds.add(placeId);

              return GestureDetector(
                onTap: () async {
                  try {
                    final placeDetails =
                        await _fetchPlaceDetails(placeId, placeName);
                    _showPlaceDetails(placeDetails);
                  } catch (e) {
                    print(
                        'Error fetching place details or Firestore places: $e');
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        color: Color.fromRGBO(141, 138, 140, 0.8),
                        border: Border.all(color: Colors.white),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      height: 200.0,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image Widget
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: 200.0,
                                    fit: BoxFit.cover,
                                  )
                                : FutureBuilder(
                                    future:
                                        _fetchPlaceDetails(placeId, placeName),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          color: Colors.grey,
                                          width: double.infinity,
                                          height: 200.0,
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return Container(
                                          color: Colors.grey,
                                          width: double.infinity,
                                          height: 200.0,
                                        );
                                      }

                                      final placeDetails = snapshot.data
                                          as Map<String, dynamic>?;
                                      final photoReference =
                                          placeDetails?['photos']?[0]
                                              ['photo_reference'];

                                      return ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        child: Image.network(
                                          _getPhotoUrl(photoReference) ?? '',
                                          width: double.infinity,
                                          height: 200.0,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0.0,
                      bottom: 8.0,
                      right: 0.0,
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16.0),
                            bottomRight: Radius.circular(16.0),
                          ),
                          color: Colors.black54,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text Column (placeName and location)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    placeName ?? 'Unknown Place',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8.0),
                                  FutureBuilder(
                                    future:
                                        _fetchPlaceDetails(placeId, placeName),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }
                                      if (snapshot.hasError) {
                                        return Text(
                                          'Error fetching location',
                                          style: TextStyle(color: Colors.white),
                                        );
                                      }

                                      final placeDetails = snapshot.data
                                          as Map<String, dynamic>?;
                                      final location =
                                          placeDetails?['formatted_address'] ??
                                              'Location not available';

                                      return Text(
                                        location,
                                        style: TextStyle(color: Colors.white),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Icon Button (bookmark)
                            IconButton(
                              icon: Icon(
                                _isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_outline_rounded,
                              ),
                              color: Colors.white,
                              onPressed: () async {
                                setState(() {
                                  _isBookmarked = !_isBookmarked;
                                });

                                if (currentUser != null && placeId != null) {
                                  final username =
                                      await _fetchUsername(currentUser.uid);

                                  if (_isBookmarked) {
                                    // Save place details to Firestore collection 'save'
                                    await _firestore.collection('save').add({
                                      'userId': currentUser.uid,
                                      'username': username,
                                      'placeId': placeId,
                                      'placeName': placeName,
                                      'imageUrl':
                                          imageUrl, // Include imageUrl here
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });

                                    // Show 'Place saved!' dialog
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Place saved!'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Ok'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    // Remove the saved place from Firestore collection 'save'
                                    final snapshot = await _firestore
                                        .collection('save')
                                        .where('userId',
                                            isEqualTo: currentUser.uid)
                                        .where('placeId', isEqualTo: placeId)
                                        .get();

                                    for (var doc in snapshot.docs) {
                                      await doc.reference.delete();
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPlaceDetails(Map<String, dynamic> place) {
    if (_selectedPlace == null) return Container();

    return Expanded(
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Container(
          padding: EdgeInsets.all(16.0),
          color: Color.fromARGB(255, 22, 23, 43),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row to align place name and bookmark icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      place['name'] ?? place['placeName'] ?? 'Unknown Place',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  IconButton(
                    icon: Icon(
                      Icons.bookmark,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null && _selectedPlace != null) {
                        // Save the place
                        final username = await _fetchUsername(currentUser.uid);

                        // Fetch image URL from Firestore place document
                        final placeDoc = await _firestore
                            .collection('place')
                            .doc(_selectedPlace!['placeId'])
                            .get();
                        final imageUrl = placeDoc.data()?['imageUrl'] ?? '';

                        // Save place details to Firestore collection 'save'
                        String placeIdToUpload = _selectedPlace!['place_id'] ??
                            _selectedPlace!['placeId'] ??
                            '';

                        await _firestore.collection('save').add({
                          'userId': currentUser.uid,
                          'username': username,
                          'placeId': placeIdToUpload,
                          'placeName': _selectedPlace!['placeName'] ??
                              _selectedPlace!['name'],
                          'imageUrl': imageUrl, // Include the image URL
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        // Show 'Place saved!' dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Place saved!'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Ok'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              // Display image from Firestore if available, otherwise from Google Maps API
              FutureBuilder<String?>(
                future: _fetchImage(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error loading image',
                        style: TextStyle(color: Colors.white));
                  }

                  final imageUrl = snapshot.data;
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    return Image.network(
                      imageUrl,
                      height: 200.0,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                    );
                  } else if (_selectedPlace!['photos'] != null &&
                      _selectedPlace!['photos'].isNotEmpty) {
                    return Image.network(
                      _getPhotoUrl(_selectedPlace!['photos'][0]
                              ['photo_reference']) ??
                          '',
                      height: 200.0,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
              SizedBox(height: 16.0),
              Text(
                place['formatted_address'] ??
                    place['description'] ??
                    'Address not available',
                style: TextStyle(color: Colors.white, fontSize: 18.0),
              ),
              SizedBox(height: 8.0),
              Text(
                'Rating:',
                style: TextStyle(color: Colors.white, fontSize: 18.0),
              ),
              SizedBox(height: 8.0),
              RatingBar.builder(
                initialRating: _selectedPlace!['rating']?.toDouble() ?? 0.0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 24.0,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    selectedRating = rating;
                  });
                },
              ),
              SizedBox(height: 16.0),
              Text(
                'Leave a Comment:',
                style: TextStyle(color: Colors.white, fontSize: 18.0),
              ),
              SizedBox(height: 8.0),
              // On TextField tap, open dialog
              GestureDetector(
                onTap: () {
                  _showCommentDialog(context);
                },
                child: Text(
                  'Tap to write a comment...',
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'Reviews:',
                style: TextStyle(color: Colors.white, fontSize: 18.0),
              ),
              SizedBox(height: 8.0),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('ratings')
                    .where('placeId', isEqualTo: _selectedPlace!['placeId'])
                    .where('place_id', isEqualTo: _selectedPlace!['place_id'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error loading reviews',
                        style: TextStyle(color: Colors.white));
                  }

                  final reviews = snapshot.hasData ? snapshot.data!.docs : [];

                  if (reviews.isEmpty) {
                    return Text(
                      'No reviews yet.',
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  return Column(
                    children: reviews.map((review) {
                      return ListTile(
                        title: Text(
                          review['username'] ?? 'Anonymous',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          review['comment'] ?? '',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: RatingBarIndicator(
                          rating: review['rating']?.toDouble() ?? 0.0,
                          itemBuilder: (context, index) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 20.0,
                          direction: Axis.horizontal,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

// Function to show the comment input dialog
  void _showCommentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Leave a Comment'),
          content: TextField(
            controller: commentTextController,
            decoration: InputDecoration(hintText: 'Write your comment here...'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null && _selectedPlace != null) {
                  final username = await _fetchUsername(currentUser.uid);
                  final comment = commentTextController.text.trim();
                  final rating = selectedRating;

                  // Fetch the place document to get the placeId
                  final placeDoc = await _firestore
                      .collection('place')
                      .doc(_selectedPlace!['placeId'])
                      .get();
                  final placeIdFromPlaceCollection =
                      placeDoc.data()?['placeId'];

                  // Add comment and rating to Firestore
                  await _firestore.collection('ratings').add({
                    'placeName':
                        _selectedPlace!['name'] ?? _selectedPlace!['placeName'],
                    'userId': currentUser.uid,
                    'username': username,
                    'place_id': _selectedPlace!['place_id'],
                    'placeId': placeIdFromPlaceCollection,
                    'comment': comment,
                    'rating': rating,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  // Clear the comment and reset the rating
                  commentTextController.clear();
                  setState(() {
                    selectedRating = 0.0;
                  });

                  // Close the dialog
                  Navigator.of(context).pop();
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _fetchImage() async {
    try {
      final snapshot = await _firestore
          .collection('place')
          .doc(_selectedPlace!['placeId'])
          .get();
      final data = snapshot.data() as Map<String, dynamic>?;

      return data?['imageUrl'] ??
          ''; // Adjust 'image_url' according to your Firestore structure
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }
}
