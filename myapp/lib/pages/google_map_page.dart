import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:myapp/pages/hub_bottom_sheet.dart';
import 'package:myapp/pages/place_botton_sheet.dart';
import 'package:myapp/pages/profile_bottom_sheet.dart';
import 'package:myapp/pages/route_bottom_sheet.dart';
import 'package:myapp/pages/saved_bottom_sheet.dart';
import 'package:myapp/pages/search_bottom_sheet.dart';
import 'package:myapp/services/routeservice.dart'; // Import RouteService class
import 'package:myapp/pages/admin_panel.dart';
import 'package:myapp/pages/route_button.dart';

class MapSample extends StatefulWidget {
  final bool showButton; // Add this line

  const MapSample({Key? key, this.showButton = false}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final Location locationController = Location();
 

  Set<Marker> _markers = Set<Marker>();
  Set<Polygon> _polygons = Set<Polygon>();
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polygonLatLngs = <LatLng>[];
  LocationData? currentLocation;

  bool _isRouteBottomSheetVisible = false;
  bool _routeActive = false;
bool _isAdmin = false;

   ValueNotifier<String> _eta = ValueNotifier<String>('');  // ValueNotifier for ETA
  ValueNotifier<String> _distance = ValueNotifier<String>('');  //
  @override
  void initState() {
    super.initState();
    getCurrentLocation(); 
     _checkAdminStatus(); // Start listening to location updates
  }

  Future<bool> checkIfUserIsAdmin() async {
  try {
    // Get the current user ID from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Fetch the user document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Check if the 'isAdmin' field is true
      if (userDoc.exists && userDoc['isAdmin'] == true) {
        return true;
      }
    }
  } catch (e) {
    print('Error checking admin status: $e');
  }
  return false;
}


void _checkAdminStatus() async {
  bool isAdmin = await checkIfUserIsAdmin();
  setState(() {
    _isAdmin = isAdmin;
  });
}
  void getCurrentLocation() async {
    try {
      var locationData = await locationController.getLocation();
      setState(() {
        currentLocation = locationData;
      });

      locationController.onLocationChanged.listen((LocationData newLoc) {
        setState(() {
          currentLocation = newLoc;
        });
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _setMarker(LatLng point) {
    setState(() {
      _markers.clear(); // Clear existing markers

      // Add other markers (if any)
      _markers.add(
        Marker(
          markerId: const MarkerId('marker'),
          position: point,
        ),
      );

      // Add current location marker if available
      if (currentLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId("currentLocation"),
            position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          ),
        );
      }
    });
  }

  void _setPolygon() {
    final String polygonIdVal = 'polygon_1';
    _polygons.add(
      Polygon(
        polygonId: PolygonId(polygonIdVal),
        points: polygonLatLngs,
        strokeWidth: 2,
        fillColor: Colors.transparent,
      ),
    );
  }

  Future<void> _showRoute(String fromAddress, String toAddress) async {
    final mapController = await _controller.future;

    // Create an instance of RouteService
    RouteService routeService = RouteService(
      context: context,
      mapController: mapController,
      markers: _markers,
      polylines: _polylines,
      routePoints: [],
      apiKey: 'AIzaSyAocNg3WkX5ppmhc-vTf1IHvG75EM1Rr5k',
    );

    // Start the route with the RouteService
    await routeService.showRoute(fromAddress: fromAddress, toAddress: toAddress);

    // Update the state to reflect the added polylines and markers
    setState(() {});
  }

Future<void> _startRoute(String fromAddress, String toAddress) async {
  final mapController = await _controller.future;

  if (currentLocation != null) {
    LatLng deviceLocation = LatLng(currentLocation!.latitude!, currentLocation!.longitude!);

    RouteService routeService = RouteService(
      context: context,
      mapController: mapController,
      markers: _markers,
      polylines: _polylines,
      routePoints: [],
      apiKey: 'AIzaSyAocNg3WkX5ppmhc-vTf1IHvG75EM1Rr5k',
    );

    try {
      await routeService.startRoute(
        toAddress,
        (estimatedTime, distance) {
          if (estimatedTime != null && distance != null) {
            print('Received estimated time: $estimatedTime');
            print('Received distance: $distance');

            // Update ValueNotifier values here
            _eta.value = estimatedTime;  // No need for setState
            _distance.value = distance;
          } else {
            print('Error: Received null values for estimated time or distance.');
          }
        },
      );
    } catch (e) {
      print('Error starting route: $e');
    }
  } else {
    print('Error: Current location is not available.');
  }
}


 Future<void> _showRouteThroughLocations(List<LatLng> locations) async {
  final GoogleMapController mapController = await _controller.future;

  if (currentLocation != null) {
    LatLng deviceLocation = LatLng(currentLocation!.latitude!, currentLocation!.longitude!);

    // Create an instance of RouteService
    RouteService routeService = RouteService(
      context: context,
      mapController: mapController,
      markers: _markers,
      polylines: _polylines,
      routePoints: [], // Pass existing routePoints
      apiKey: 'AIzaSyAocNg3WkX5ppmhc-vTf1IHvG75EM1Rr5k',
    );

    try {
      print('Calling routeService.routeThroughLocations...');
      // Show the route through the provided locations
      await routeService.routeThroughLocations(locations, (estimatedTimes, distance, locationName)  {
        });
      print('routeService.routeThroughLocations called successfully.');

      // Update the state to reflect the added polylines and markers
      setState(() {});
    } catch (e) {
      print('Error showing route through locations: $e');
    }
  }
}
  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      // Show loading indicator or alternative UI while waiting for location
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            GoogleMap(
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              markers: _markers,
              polygons: _polygons,
              polylines: _polylines,
              trafficEnabled: true, // Enable real-time traffic
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!),
                zoom: 14.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
           
            Positioned(
              bottom: 15.0,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: const Color(0xff596E83),
                  borderRadius: BorderRadius.circular(100.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 45.0,
                      spreadRadius: 120.0,
                      offset: Offset(0.0, 140.0),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 420,
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          displayBottomSheet_search(context);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                            Text(
                              'Search',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          elevation: 0.0,
                          overlayColor: Colors.white,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_controller.isCompleted) {
                            final mapController = await _controller.future;
                            displayBottomSheet_route(
                              context,
                              mapController,
                              _markers,
                              _polylines,
                              [], // Pass empty list or existing routePoints
                            );
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.route, color: Colors.white),
                            Text(
                              'Route',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          elevation: 0.0,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          displayBottomSheet_hub(context);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                Icons.phone_android,
                                color: Colors.white),
                            Text(
                              'Hub',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          elevation: 0.0,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          displayBottomSheet_saved(context);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                Icons.bookmark_border,
                                color: Colors.white),
                            Text(
                              'Saved',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          elevation: 0.0,
                        ),
                      ),
                      ElevatedButton(
                         onPressed: () async {
                          if (_controller.isCompleted) {
                            final mapController = await _controller.future;
                            displayBottomSheet_profile(
                              context,
                              mapController,
                              _markers,
                              _polylines,
                              [], // Pass empty list or existing routePoints
                            );
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, color: Colors.white),
                            Text(
                              'Profile',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          elevation: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 90.0,
              right: 10.0,
              child: FloatingActionButton(
                 onPressed: () {
                   displayBottomSheet_place(context);
                },
                child: Icon(Icons.location_on),
              ),
            ),
            Positioned(
  top: 50.0,
  right: 16.0,
  child: _isAdmin
      ? FloatingActionButton(
          onPressed: () {
            // Trigger the admin panel UI when this button is pressed
            displayAdminPanel(context);
          },
          child: const Icon(Icons.phone_android),
        )
      : Container(), // Empty container if the user is not an admin
),


          // Your map or other content goes here
          RouteButton(
  isVisible: widget.showButton,
  onPressed: () {
    print("Route button pressed");
  },
),
        ],
         
        ),
      );
    }
  }
}
