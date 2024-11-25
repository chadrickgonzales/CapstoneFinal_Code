import 'dart:convert'; // For JSON decoding

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/pages/route_button.dart';
import 'package:myapp/services/routeservice.dart'; // Import the RouteService

void displayBottomSheet_route(
  BuildContext context,
  GoogleMapController mapController,
  Set<Marker> markers,
  Set<Polyline> polylines,
  List<LatLng> routePoints,
) {
  // Create an instance of RouteService
  RouteService routeService = RouteService(
    context: context,
    mapController: mapController,
    markers: markers,
    polylines: polylines,
    routePoints: routePoints,
    apiKey:
        'AIzaSyCffo3J5Oo5udtLKhLnR8Bzl2XT7f3CbHk', // Replace with your API key
  );

  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();
  List<dynamic> fromSuggestions = [];
  List<dynamic> toSuggestions = [];
  bool fromSuggestionsVisible = false;
  bool toSuggestionsVisible = false;
  bool showFAB = false; // Variable to control FAB visibility
  ValueNotifier<bool> isLoading =
      ValueNotifier<bool>(false); // ValueNotifier for loading state
  OverlayEntry? containerEntry;
  OverlayEntry? fabEntry;
  OverlayState? overlayState;

  String _eta = '';
  String _distance = '';
  void setState(Null Function() param0) {
  }
  // Function to fetch related places from Google Maps API
  Future<void> fetchRelatedPlaces(String query, bool isFrom) async {
    final String googleMapsApiKey = 'AIzaSyCffo3J5Oo5udtLKhLnR8Bzl2XT7f3CbHk';
    final String googleMapsUrl =
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$googleMapsApiKey';

    try {
      final googleResponse = await http.get(Uri.parse(googleMapsUrl));
      if (googleResponse.statusCode == 200) {
        final googleData = json.decode(googleResponse.body);
        if (googleData['status'] == 'OK') {
          List<dynamic> googlePlaces = googleData['results'];
          if (isFrom) {
            fromSuggestions = googlePlaces;
          } else {
            toSuggestions = googlePlaces;
          }
        } else {
          print('Google API Error: ${googleData['status']}');
        }
      } else {
        print('Google Maps API Error: ${googleResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching places from Google API: $e');
    }

    // Fetch from Firestore
    try {
      final firestorePlaces = await FirebaseFirestore.instance
          .collection('place')
          .where('placeName', isGreaterThanOrEqualTo: query)
          .where('placeName', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      if (firestorePlaces.docs.isNotEmpty) {
        List<dynamic> firestoreResults = firestorePlaces.docs.map((doc) {
          return {
            'placeName': doc['placeName'],
            'location': doc['location'], // GeoPoint type
          };
        }).toList();

        if (isFrom) {
          fromSuggestions.addAll(firestoreResults);
        } else {
          toSuggestions.addAll(firestoreResults);
        }
      }
    } catch (e) {
      print('Error fetching places from Firestore: $e');
    }

    (context as Element).markNeedsBuild(); // Trigger rebuild to show updated places
  }

  // Handle place selection
  void handlePlaceSelection(dynamic place, bool isFrom) {
    if (place.containsKey('location') && place['location'] is GeoPoint) {
      GeoPoint geoPoint = place['location'];
      LatLng location = LatLng(geoPoint.latitude, geoPoint.longitude);
      
      if (isFrom) {
        fromController.text = place['placeName'] ?? '';
        routeService.showRoute(fromLocation: location, toAddress: toController.text);
      } else {
        toController.text = place['placeName'] ?? '';
        routeService.showRoute(fromAddress: fromController.text, toLocation: location);
      }
    } else {
      if (isFrom) {
        fromController.text = place['name'] ?? '';
        routeService.showRoute(fromAddress: fromController.text, toAddress: toController.text);
      } else {
        toController.text = place['name'] ?? '';
        routeService.showRoute(fromAddress: fromController.text, toAddress: toController.text);
      }
    }

    (context as Element).markNeedsBuild(); // Trigger rebuild
  }
  // Function to handle API response and display places
  Future<void> handleApiResponse(String query, bool isFrom) async {
    // Fetch places from both Google Maps API and Firestore
    await fetchRelatedPlaces(query, isFrom);

    if (isFrom) {
      fromSuggestionsVisible = true;
    } else {
      toSuggestionsVisible = true;
    }

    (context as Element).markNeedsBuild(); // Trigger rebuild to show updated places
  }

  void showContainer(BuildContext context, String message, {String? destinationName, double? distance, String? estimatedTime}) {
    overlayState = Overlay.of(context);

    if (overlayState == null) {
      print('OverlayState is not available');
      return;
    }

    containerEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! > 5) {
              containerEntry?.remove(); // Close the container
              showFAB = true;
              // Reinsert FAB after closing the container
             
              overlayState?.insert(fabEntry!);
            }
          },
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xff596E83), // Change container color here
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (message == 'Starting route from device location')
                  
                    Column(
                      children: [
                        SizedBox(height: 16.0),
                        Center(
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (destinationName != null && distance != null && estimatedTime != null) ...[
                         
                          
                          SizedBox(height: 8.0),
                          
                          
                          Text(
                            'Destination: $destinationName',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Distance: ${distance.toStringAsFixed(2)} km',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Estimated Time: $estimatedTime',
                            style: TextStyle(color: Colors.white),
                          ),

                          
                        ],

                        
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () {
                            // Cancel the route operation
                            routeService.cancelRoute(); // Call cancelRoute from RouteService

                            isLoading.value = false; // Hide the progress bar

                            // Close the current container
                            containerEntry?.remove();
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red, // Set text color to white
                          ),
                          child: Text('Cancel'),
                        ),
                      ],
                    ),
                  if (message == 'Route is being displayed')
ValueListenableBuilder<bool>(
  valueListenable: isLoading,
  builder: (context, loading, child) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            String from = fromController.text;
            String to = toController.text;


            // Show the progress bar
            isLoading.value = true;
 containerEntry?.remove();
            try {
              // Call startRoute from RouteService instance and await the result
              Map<String, dynamic> routeResult = await routeService.startRoute(
                to,
                (eta, distance) {
                  // Assuming you have a way to update ETA and distance
                  _eta = eta; 
                  _distance = distance; 
                },
              );

              if (routeResult.isNotEmpty) {
                // Retrieve dynamic route values
                String destinationName = routeResult['destinationName'] ?? 'Unknown destination';
                double distance = routeResult['distance'] ?? 0.0;
                String estimatedTime = routeResult['eta'] ?? 'Unknown ETA';

              

                // Show the container with the dynamic values
                showContainer(context, 'Starting route from device location',
                    destinationName: destinationName,
                    distance: distance,
                    estimatedTime: estimatedTime);
              } else {
                // Handle case when no route is found
                print('No route found.');
              }
            } catch (error) {
              // Log any errors encountered during route retrieval
              print('Error showing route: $error');
            } finally {
              // Hide the progress bar once operation completes
              isLoading.value = false;
            }
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color.fromARGB(255, 80, 96, 116), // Set background color
          ),
          child: Text('Start Route'),
        ),
        if (loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  },
),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState!.insert(containerEntry!);
  }
  


  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Make the background transparent
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return FractionallySizedBox(
            heightFactor: 0.95, // Adjust the height factor as needed
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color:
                    Color.fromARGB(225, 41, 42, 60), // Set the background color
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Start Route',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Set text color to white
                    ),
                  ),
                  SizedBox(height: 16.0),
                  
                TextField(
                    controller: fromController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'From',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        fetchRelatedPlaces(value, true); // Changed to 'true' for "From"
                        setState(() {
                          fromSuggestionsVisible = true;
                        });
                      } else {
                        setState(() {
                          fromSuggestionsVisible = false;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 8.0),
                  if (fromSuggestionsVisible)
                    Container(
                      height: 200.0,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(141, 138, 140, 0.8),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListView.builder(
                        itemCount: fromSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = fromSuggestions[index];
                          return ListTile(
                            title: Text(
                              suggestion['placeName'] ?? suggestion['name'],
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () => handlePlaceSelection(suggestion, true),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: toController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'To',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        fetchRelatedPlaces(value, false); // Changed to 'false' for "To"
                        setState(() {
                          toSuggestionsVisible = true;
                        });
                      } else {
                        setState(() {
                          toSuggestionsVisible = false;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 8.0),
                  if (toSuggestionsVisible)
                    Container(
                      height: 200.0,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(141, 138, 140, 0.8),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListView.builder(
                        itemCount: toSuggestions.length,
                        itemBuilder: (context, index) {
                          final place = toSuggestions[index];
                          return ListTile(
                            title: Text(
                              place['placeName'] ?? place['name'] ?? 'No Name',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              toController.text = place['placeName'] ?? place['name'] ?? '';
                              setState(() {
                                toSuggestionsVisible = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 16.0),
                  ValueListenableBuilder<bool>(
                    valueListenable: isLoading,
                    builder: (context, loading, child) {
                      return Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              String from = fromController.text;
                              String to = toController.text;

                              isLoading.value = true; // Show the progress bar

                              // Call showRoute from RouteService instance
                              routeService.showRoute(fromAddress: from, toAddress: to).then((_) {
                                isLoading.value = false; // Hide the progress bar
                              }).catchError((error) {
                                isLoading.value = false; // Hide the progress bar even in case of error
                                print('Error showing route: $error');
                              });

                              Navigator.pop(context); // Close the bottom sheet
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Color.fromARGB(255, 80, 96, 116),
                            ),
                            child: Text('Show Route'),
                          ),
                          if (loading) SizedBox(height: 16.0),
                          if (loading)
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
