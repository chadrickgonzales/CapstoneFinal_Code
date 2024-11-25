import 'dart:async';
import 'dart:convert'; // For JSON decoding
import 'dart:math' as math; // Import for mathematical operations
import 'dart:math';
import 'package:myapp/pages/google_map_page.dart';
import 'package:myapp/pages/route_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import '../pages/  route_info_bottom_sheet.dart';



class RouteService {
  bool _isLocationRequestCancelled = false;
  bool _isRouteCancelled = false;
  bool isLocationUpdatesCancelled = false;
  StreamSubscription? progressStreamSubscription;
  bool isRouteCancelled = false;
  bool _showButton = false; 
  bool get showButton => _showButton;
  final BuildContext context;
  final GoogleMapController mapController;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final List<LatLng> routePoints;
  final String apiKey;

  List<String> _locationNames = [];
List<String> _estimatedTimes = [];
List<double> _remainingDistances = [];

  late Location _location;
  late StreamSubscription<LocationData> _locationSubscription;

  List<LatLng> _deviceRoutePoints = [];
  LatLng? _destinationLocation;
  final progressStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
      Location device = Location();

      

  RouteService({
    required this.context,
    required this.mapController,
    required this.markers,
    required this.polylines,
    required this.routePoints,
    required this.apiKey,
  }) {
    _location = Location();
    _startLocationUpdates();
  }

  Stream<Map<String, dynamic>> get progressStream =>
      progressStreamController.stream;



 void _startLocationUpdates() {
  _locationSubscription = _location.onLocationChanged.listen((LocationData locationData) {
    if (isLocationUpdatesCancelled) {
      // Stop further updates if canceled
      _locationSubscription?.cancel();
      return;
    }

    if (locationData.latitude != null && locationData.longitude != null) {
      LatLng newDeviceLocation = LatLng(locationData.latitude!, locationData.longitude!);
      _updateDeviceMarker(newDeviceLocation);
      _updateDeviceRoute(newDeviceLocation);

      if (_destinationLocation != null) {
        calculateProgress(newDeviceLocation, _destinationLocation!);
      }
    }
  });
}

void _updateDeviceMarker(LatLng newLocation) {
  if (isLocationUpdatesCancelled) {
    // Stop updating if canceled
    return;
  }
  markers.removeWhere((marker) => marker.markerId.value == 'device');
  markers.add(Marker(
    markerId: MarkerId('device'),
    position: newLocation,
    infoWindow: InfoWindow(title: 'Your Location'),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  ));
}

Future<void> _updateDynamicRoute(LatLng newLocation) async {
  if (isLocationUpdatesCancelled) {
    // Stop updating if canceled
    return;
  }

  if (_destinationLocation != null) {
    List<LatLng> newRoute = await _getRoute(newLocation, _destinationLocation!);

    if (newRoute.isNotEmpty) {
      routePoints.clear();
      routePoints.addAll(newRoute);

      polylines.removeWhere((polyline) => polyline.polylineId.value == 'route');
      polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 5,
      ));

      // Adjust the camera view
      mapController.animateCamera(CameraUpdate.newLatLng(newLocation));
      print("Route updated with ${newRoute.length} points.");
    } else {
      print("No new route points found.");
    }
  }
}

  Future<void> _updateDeviceRoute(LatLng newLocation) async {
    if (_deviceRoutePoints.isEmpty || _deviceRoutePoints.last != newLocation) {
      _deviceRoutePoints.add(newLocation);

      if (isLocationUpdatesCancelled) {
    // Stop updating if canceled
    return;
  }
      // Update the dynamic route
      await _updateDynamicRoute(newLocation);

      // Adjust the camera view
      mapController.animateCamera(CameraUpdate.newLatLng(newLocation));
      print("Device route updated with ${_deviceRoutePoints.length} points.");
    }
  }

  Future<void> showRoute({
  String? fromAddress,
  String? toAddress,
  LatLng? fromLocation,
  LatLng? toLocation,
}) async {
  // If fromLocation is not provided, get it from the address
  if (fromLocation == null && fromAddress != null) {
    fromLocation = await _getLatLngFromAddress(fromAddress);
  }

  // If toLocation is not provided, get it from the address
  if (toLocation == null && toAddress != null) {
    toLocation = await _getLatLngFromAddress(toAddress);
  }

  // Ensure both locations are valid before proceeding
  if (fromLocation != null && toLocation != null) {
    markers.clear();
    polylines.clear();
    routePoints.clear();

    // Add markers for "from" location
    markers.add(Marker(
      markerId: MarkerId('from'),
      position: fromLocation,
      infoWindow: InfoWindow(title: fromAddress ?? 'Start Location'),
    ));

    // Add markers for "to" location
    markers.add(Marker(
      markerId: MarkerId('to'),
      position: toLocation,
      infoWindow: InfoWindow(title: toAddress ?? 'Destination'),
    ));

    // Get the route between the two locations
    List<LatLng> route = await _getRoute(fromLocation, toLocation);

    if (route.isNotEmpty) {
      routePoints.addAll(route);
      polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 5,
      ));

      // Create bounds for the map camera to focus on the route
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          math.min(fromLocation.latitude, toLocation.latitude),
          math.min(fromLocation.longitude, toLocation.longitude),
        ),
        northeast: LatLng(
          math.max(fromLocation.latitude, toLocation.latitude),
          math.max(fromLocation.longitude, toLocation.longitude),
        ),
      );

      // Animate the camera to fit the route
      if (mapController != null) {
        mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
      } else {
        print('Error: MapController is not initialized.');
      }
    } else {
      print('Error: Unable to fetch route from Directions API.');
    }
  } else {
    print('Error: One or both locations could not be determined.');
  }
}

  PersistentBottomSheetController? _bottomSheetController;
  RouteInfoBottomSheetState? _bottomSheetState;
  OverlayEntry? _routeInfoOverlay;

  void _showRouteInfoBottomSheet(
      String estimatedTime, String distance, String toAddress) {
    if (_routeInfoOverlay == null) {
      // State variables for overlay position and minimized state
      Offset overlayPosition = Offset(30, 30); // Initial position
      bool isMinimized = false;

      // Create the overlay entry
      _routeInfoOverlay = OverlayEntry(
        builder: (BuildContext context) {
          return Positioned(
            left: overlayPosition.dx,
            top: overlayPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                // Update overlay position in real-time during drag
                overlayPosition += details.delta;
                _routeInfoOverlay?.markNeedsBuild();
              },
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMinimized ? 70 : 340,
                    maxHeight: isMinimized ? 70 : 245,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minimize/Expand Button Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isMinimized ? Icons.explore : Icons.minimize,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                // Toggle minimize state and rebuild overlay
                                isMinimized = !isMinimized;
                                _routeInfoOverlay?.markNeedsBuild();
                              },
                            ),
                          ),
                        ],
                      ),
                      if (!isMinimized)
                        Expanded(
                          child: SizedBox(
                            width: 300,
                            height: 120,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15), // Add border radius here
                              child: RouteInfoBottomSheet(
                                estimatedTime: estimatedTime,
                                distance: distance,
                                destination: toAddress,
                                routeService: RouteService(
                                  context: context,
                                  mapController: mapController,
                                  markers: markers,
                                  polylines: polylines,
                                  routePoints: routePoints,
                                  apiKey: apiKey,
                                ),
                                onStateCreated:
                                    (RouteInfoBottomSheetState state) {
                                  _bottomSheetState = state;
                                },
                                onClose: () {
                                  _removeRouteInfoOverlay();
                                  _showButton = true;
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      // Insert the overlay entry
      final overlay = Overlay.of(context);
      if (overlay != null) {
        overlay.insert(_routeInfoOverlay!);
      }
    } else {
      // If the overlay is already shown, update it
      _updateBottomSheet(estimatedTime, distance);
    }
  }

// Function to remove the overlay
  void _removeRouteInfoOverlay() {
    _routeInfoOverlay?.remove();
    _routeInfoOverlay = null;
  }

// Function to update the overlay content
  void _updateBottomSheet(String estimatedTime, String distance) {
    if (_bottomSheetState != null) {
      _bottomSheetState!.updateRouteInfo(estimatedTime, distance);
    }
  }


   StreamSubscription? progressSubscription;



Future<Map<String, dynamic>> startRoute(
    String toAddress,
    Function(String estimatedTime, String distance) onRouteInfoUpdate,
) async {
   if (isRouteCancelled ) {
                // Stop updating if the route is canceled
                 print('route stop');
                return{};
              }
    LatLng? deviceLocation = await _getCurrentLocation();
    if (deviceLocation == null) {
        print('Error: Unable to get device location.');
        return {};
    }

    // Clear previous markers and routes
    markers.clear();
    polylines.clear();
    routePoints.clear();
    _deviceRoutePoints.clear();

    // Add marker for the device location
    markers.add(Marker(
        markerId: MarkerId('device'),
        position: deviceLocation,
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));

    // Get the LatLng for the destination
    LatLng? toLocation = await _getLatLngFromAddress(toAddress);
    if (toLocation != null) {
        _destinationLocation = toLocation;

        // Add marker for the destination
        markers.add(Marker(
            markerId: MarkerId('destination'),
            position: toLocation,
            infoWindow: InfoWindow(title: 'Destination: $toAddress'),
        ));

        // Get the route from device location to destination
        List<LatLng> route = await _getRoute(deviceLocation, toLocation);
        if (route.isNotEmpty) {
            routePoints.addAll(route);
            polylines.add(Polyline(
                polylineId: PolylineId('route'),
                points: routePoints,
                color: Colors.blue,
                width: 5,
            ));

            // Set bounds to fit both device location and destination on the map
           LatLngBounds bounds = LatLngBounds(
    southwest: LatLng(
      math.min(deviceLocation.latitude, toLocation.latitude),
      math.min(deviceLocation.longitude, toLocation.longitude),
    ),
    northeast: LatLng(
      math.max(deviceLocation.latitude, toLocation.latitude),
      math.max(deviceLocation.longitude, toLocation.longitude),
    ),
  );

  // Calculate midpoint between the two locations
  LatLng midpoint = LatLng(
    (deviceLocation.latitude + toLocation.latitude) / 2,
    (deviceLocation.longitude + toLocation.longitude) / 2,
  );

  // Animate to midpoint with an initial zoom for smooth transition
  mapController.animateCamera(CameraUpdate.newLatLngZoom(midpoint, 14.0));

  // Follow up with bounds animation to include both locations after a delay
  Future.delayed(Duration(milliseconds: 500), () {
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  });

            // Call _calculateProgress to start calculating the distance and ETA
            await calculateProgress(deviceLocation, toLocation);

            // Listen for progress updates from the stream
            progressStreamSubscription = progressStreamController.stream.listen((progress) {
              if (isRouteCancelled) {
                // Stop updating if the route is canceled
                progressStreamSubscription?.cancel();
                return;
              }

              double distance = progress['distance'];
              String estimatedTime = progress['estimatedTime'];

              // Update the route information on the bottom sheet
              onRouteInfoUpdate(estimatedTime, distance.toStringAsFixed(2));

              // Show the bottom sheet with updated route information
              _showRouteInfoBottomSheet(estimatedTime, distance.toStringAsFixed(2), toAddress); // Pass toAddress
            });

            // Return the initial route information (can be empty since updates are handled via stream)
            return {
                'destinationName': toAddress,
            };
        } else {
            print('Error: Unable to fetch route from Directions API.');
        }
    } else {
        print('Error: Destination address could not be geocoded.');
    }

    return {};
}

Future<String> _calculateETA(double distance) async {
  Location location = Location();
  
  // Ensure location services are enabled and permissions are granted
  bool serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      return 'Location services are disabled';
    }
  }

  PermissionStatus permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      return 'Location permission not granted';
    }
  }

  // Get current location data, including speed
  LocationData currentLocation = await location.getLocation();

  // Use device's speed if available, otherwise fall back to an average speed
  double speed = currentLocation.speed ?? 0; // Speed is in meters per second (m/s)

  // Convert speed from m/s to km/h
  double speedKmH = speed * 3.6;

  if (speedKmH <= 0) {
    // If speed is not available or device is stationary, return a default message or value
    return 'Speed data not available';
  }

  // Calculate ETA using the device's speed
  double hours = distance / speedKmH;
  int minutes = (hours * 60).round();

  return '${minutes} min';
}

 Future<LatLng?> _getCurrentLocation() async {
  if (_isLocationRequestCancelled) {
    print("Location request has been cancelled.");
    return null;
  }

  try {
    final LocationData locationData = await _location.getLocation();

    if (_isLocationRequestCancelled) {
      print("Location request has been cancelled after receiving location data.");
      return null;
    }
 print("Current location: Latitude: , Longitude: ");
    return LatLng(locationData.latitude!, locationData.longitude!);
    
  } catch (e) {
    print("Error getting current location: $e");
    return null;
  }
}

  Future<List<LatLng>> _getRoute(LatLng from, LatLng to) async {
  if (_isRouteCancelled) {
    print("Route fetching has been cancelled.");
    return [];
  }

  final String url =
      'https://maps.googleapis.com/maps/api/directions/json?origin=${from.latitude},${from.longitude}&destination=${to.latitude},${to.longitude}&key=$apiKey';

  try {
    final response = await http.get(Uri.parse(url));

    // Check again after the response is received in case of cancellation during fetch
    if (_isRouteCancelled) {
      print("Route fetching has been cancelled after receiving response.");
      return [];
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final routes = data['routes'];
      if (routes.isNotEmpty) {
        final points = routes[0]['overview_polyline']['points'];
        return _decodePolyline(points);
      } else {
        print("No routes found for the given points.");
        return [];
      }
    } else {
      print("Failed to fetch data from Directions API: ${response.statusCode}");
      return [];
    }
  } catch (e) {
    print("Error fetching route: $e");
    return [];
  }
}

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      final LatLng position = LatLng(
        (lat / 1E5),
        (lng / 1E5),
      );
      polyline.add(position);
    }
    return polyline;
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
  try {
    // Step 1: Check Firestore for the place
    final firestorePlaces = await FirebaseFirestore.instance
        .collection('place')
        .where('placeName', isEqualTo: address) // Exact match for place name
        .get();

    if (firestorePlaces.docs.isNotEmpty) {
      // If place found in Firestore, return its GeoPoint as LatLng
      final GeoPoint geoPoint = firestorePlaces.docs.first['location'];
      return LatLng(geoPoint.latitude, geoPoint.longitude);
    } else {
      print("Place not found in Firestore, trying Google Geocoding API...");
    }

    // Step 2: If not found in Firestore, use Google Maps Geocoding API
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      } else {
        print("No results found for the given address in Google API.");
        return null;
      }
    } else {
      print("Failed to fetch data from Geocoding API: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Error fetching location data: $e");
    return null;
  }
}

 Future<void> calculateProgress(LatLng newDeviceLocation, LatLng destinationLocation) async {
   if (isRouteCancelled) {
    return;  // If route is cancelled, stop calculating progress.
  }
  double distance = _calculateDistance(newDeviceLocation, destinationLocation);
  String estimatedTime = await _calculateETA(distance);

  progressStreamController.add({
    'distance': distance,
    'estimatedTime': estimatedTime,

    
  });
  
}

  double _calculateDistance(LatLng start, LatLng end) {
  const double earthRadius = 6371000; // in meters
  double dLat = _toRadians(end.latitude - start.latitude);
  double dLon = _toRadians(end.longitude - start.longitude);
  double lat1 = _toRadians(start.latitude);
  double lat2 = _toRadians(end.latitude);

  double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLon / 2) * math.sin(dLon / 2) *
      math.cos(lat1) * math.cos(lat2);
  double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  // Convert the distance from meters to kilometers
  return (earthRadius * c) / 1000; // Convert to kilometers
}
  double _toRadians(double degree) => degree * math.pi / 180;

  void dispose() {
    _locationSubscription.cancel();
    progressStreamController.close();
     isRouteCancelled = true;
  }

  void cancelRoute() {
    restartApp; 
    _isLocationRequestCancelled = true;
    _isRouteCancelled = true;
     isLocationUpdatesCancelled = true;
   isRouteCancelled = true;
    progressStreamSubscription?.cancel();
     progressSubscription?.cancel();
     _routeInfoOverlay?.remove();
    _routeInfoOverlay = null;
  // Clear all markers
  markers.clear();
   progressStreamController.close();
    _locationSubscription.cancel();


  // Remove all polylines
  polylines.removeWhere((polyline) => polyline.polylineId.value == 'route');

  // Clear route and device route points
  routePoints.clear();
  _deviceRoutePoints.clear();

  // Stop location updates
  _locationSubscription.cancel();
  
  // Close the progress stream controller
  progressStreamController.close();
  
  print('Route canceled and all markers cleared.');

  _removeRouteInfoOverlay();
  print('Route info overlay removed.');

  // 4. Optionally, reset any other state variables or stop any active calculations here
  _destinationLocation = null;
  print('Route canceled and state reset.');
}
Future<void> routeThroughLocations(
  List<LatLng> locations,
  Function(String estimatedTime, String distance, String locationName) onRouteInfoUpdate,
) async {
  print('Starting routeThroughLocations with ${locations.length} locations.');

  if (locations.isEmpty) {
    print('At least one location is required to start routing.');
    return;
  }

  // Get the device's initial location
  LatLng? deviceLocation = await _getCurrentLocation();
  if (deviceLocation == null) {
    print('Error: Unable to get device location.');
    return;
  }

  print('Device location obtained: $deviceLocation');

  // Clear previous markers and polylines
  markers.clear();
  routePoints.clear();

  // Add marker for the current device location
  markers.add(Marker(
    markerId: MarkerId('device'),
    position: deviceLocation,
    infoWindow: InfoWindow(title: 'Your Location'),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  ));

  // Initialize index for the current location
  int currentIndex = 0;

  while (currentIndex < locations.length) {
    final LatLng toLocation = locations[currentIndex];

    // Determine the starting point
    LatLng fromLocation = (currentIndex == 0) ? deviceLocation : locations[currentIndex - 1];

    print('Routing from: $fromLocation to: $toLocation');

    // Fetch the route between fromLocation and toLocation
    List<LatLng> route = await _getRoute1(fromLocation, toLocation);
    if (route.isNotEmpty) {
      routePoints.addAll(route);
      print('Route obtained with ${route.length} points.');
    } else {
      print('No route found between locations.');
      currentIndex++; // Move to the next location if no route is found
      continue; // Skip to the next iteration
    }

    // Add marker for each stop location
    markers.add(Marker(
      markerId: MarkerId('location_$currentIndex'),
      position: toLocation,
      infoWindow: InfoWindow(title: 'Stop ${currentIndex + 1}'),
    ));


    setState(() {
      polylines.add(Polyline(
        polylineId: PolylineId("route_$currentIndex"),
        points: routePoints,
        color: Colors.blue,
        width: 5,
      ));
    });

    print('Polyline added for route $currentIndex with ${routePoints.length} points.');

    // Fetch location name
    String locationName = await _getLocationName(toLocation);

    // Initialize previous values
    String previousEstimatedTime = '';
    String previousDistance = '';

    // Track device movement using a location listener
    StreamSubscription<LocationData>? locationSubscription;
    locationSubscription = device.onLocationChanged.listen((LocationData currentLocation) async {
      LatLng updatedDeviceLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);

      // Recalculate distance and time to the next stop (toLocation)
      String estimatedTime = await _getEstimatedTime(updatedDeviceLocation, toLocation);
      double distance = await _calculateRemainingDistance(updatedDeviceLocation, toLocation);
      String distanceStr = distance.toString();

      // Check for changes in estimated time or distance
      if (estimatedTime != previousEstimatedTime || distanceStr != previousDistance) {
        // Update the callback with new values
        onRouteInfoUpdate(estimatedTime, distanceStr, locationName);

        // Store current values for future comparison
        previousEstimatedTime = estimatedTime;
        previousDistance = distanceStr;

        // Print statement to check for data changes
        print('Data Updated: Distance to next stop: $distanceStr meters, Estimated Time: $estimatedTime');
      }
    });

    // Wait for the device to arrive at the destination
    bool arrived = await waitForArrival(toLocation);
    if (arrived) {
      print('Device has arrived at location $toLocation.');
      locationSubscription?.cancel(); // Stop location updates for this segment

      // Move to the next location
      currentIndex++;
      
      // Reset the routePoints for the next leg
      routePoints.clear(); 
       markers.clear();
    }
       


    
    // If the device has reached the last location, clear markers
    if (currentIndex >= locations.length) {
      print('Device has arrived at the last location. Clearing markers.');
      markers.clear();
      return;
    }

    // Update polyline and animate camera after each route
 
    // Animate camera to show the current route
    LatLngBounds bounds = _createBoundsForLocations(deviceLocation, locations);
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  print('Routing through ${locations.length} locations completed.');
}
// Function to wait until the device arrives at a specified location
Future<bool> waitForArrival(LatLng destination) async { // Time in seconds to wait before giving up
  const double arrivalThreshold = 100; // Adjust as needed for arrival precision

  print('Waiting for arrival at destination: $destination');

  Timer? timer;
  bool arrived = false;

  // Start a timer to handle the timeout
 

  while (!arrived) {
    LatLng? currentLocation = await _getCurrentLocation();
    if (currentLocation == null) {
      print('Error: Unable to get current location during wait.');
      return false;
    }

    double distance = _calculateDistance1(currentLocation, destination);
    print('Current location: $currentLocation, Distance to destination: $distance meters.');

    if (distance < arrivalThreshold) {
      arrived = true;
      timer?.cancel(); // Cancel the timer if arrival is detected
    }

    await Future.delayed(Duration(seconds: 5)); // Check every 5 seconds
  }

  print('Arrived at destination: $destination');
  return true;
}


// Helper function to calculate the distance between two LatLng points
double _calculateDistance1(LatLng start, LatLng end) {
  const double earthRadius = 6371000; // Earth's radius in meters

  double dLat = _degreesToRadians(end.latitude - start.latitude);
  double dLng = _degreesToRadians(end.longitude - start.longitude);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(start.latitude)) * cos(_degreesToRadians(end.latitude)) *
      sin(dLng / 2) * sin(dLng / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c; // Distance in meters
} 

// Helper function to convert degrees to radians
double _degreesToRadians(double degrees) {
  return degrees * (pi / 180);
}  
// Placeholder function to get current location

// Placeholder for the setState method
void setState(VoidCallback fn) {
  // Implement state management
  print('Calling setState.');
  fn();
}
LatLngBounds _createBoundsForLocations(LatLng deviceLocation, List<LatLng> locations) {
  // Initialize the bounds with the device's location
  double minLat = deviceLocation.latitude;
  double minLng = deviceLocation.longitude;
  double maxLat = deviceLocation.latitude;
  double maxLng = deviceLocation.longitude;

  // Expand the bounds to include all provided locations
  for (LatLng location in locations) {
    if (location.latitude < minLat) minLat = location.latitude;
    if (location.latitude > maxLat) maxLat = location.latitude;
    if (location.longitude < minLng) minLng = location.longitude;
    if (location.longitude > maxLng) maxLng = location.longitude;
  }

  // Create and return LatLngBounds
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

Future<List<LatLng>> _getRoute1(LatLng from, LatLng to) async {
  print('Fetching route from $from to $to.');

  // Replace with your Google Directions API key
  const String apiKey = 'AIzaSyANC6OfmrgsOcypf8rHrKaVCvvS89kQRMM';

  final String url =
      'https://maps.googleapis.com/maps/api/directions/json?origin=${from.latitude},${from.longitude}&destination=${to.latitude},${to.longitude}&key=$apiKey';

  try {
    final response = await http.get(Uri.parse(url));

    print('API response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final String encodedPolyline =
            data['routes'][0]['overview_polyline']['points'];

        print('Encoded polyline: $encodedPolyline');

        // Decode the polyline using the _decodePolyline function
        return _decodePolyline1(encodedPolyline);
      } else {
        print('Error fetching route: ${data['status']}');
        return [];
      }
    } else {
      print('Failed to connect to the Directions API');
      return [];
    }
  } catch (e) {
    print("Error fetching route: $e");
    return [];
  }
}
List<LatLng> _decodePolyline1(String encoded) {
  print('Decoding polyline: $encoded');

  List<LatLng> polyline = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    polyline.add(LatLng(lat / 1E5, lng / 1E5));
  }

  print('Decoded polyline with ${polyline.length} points.');
  return polyline;
}



 Future<String> _getLocationName(LatLng location) async {
  final apiKey = 'AIzaSyCffo3J5Oo5udtLKhLnR8Bzl2XT7f3CbHk'; // Replace with your API key
  final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$apiKey';

  final response = await http.get(Uri.parse(url));
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['status'] == 'OK' && data['results'].isNotEmpty) {
      return data['results'][0]['formatted_address'];
    }
  }
  return 'Unknown Location';
}
Future<String> _getEstimatedTime(LatLng from, LatLng to) async {
  const String apiKey = 'AIzaSyANC6OfmrgsOcypf8rHrKaVCvvS89kQRMM'; // Replace with your API key
  final String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${from.latitude},${from.longitude}&destination=${to.latitude},${to.longitude}&key=$apiKey';

  final response = await http.get(Uri.parse(url));
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
      return data['routes'][0]['legs'][0]['duration']['text'];
    }
  }
  return 'Unknown Duration';
}
Future<double> _calculateRemainingDistance(LatLng from, LatLng to) async {
  print('Calculating remaining distance from $from to $to');
  double distance = _calculateDistance1(from, to);
  print('Remaining distance: $distance meters');
  return distance;
}
  // Getter methods
  List<String> getLocationNames() => _locationNames;
  List<String> getEstimatedTimes() => _estimatedTimes;
  List<double> getRemainingDistances() => _remainingDistances;
  
  void showContainer(BuildContext context, String s, {required String destinationName, required double distance, required String estimatedTime}) {}


@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Your main content
          RouteButton(
            isVisible: _showButton,
            onPressed: () {
              // Handle button press
              print('Route button pressed');
            },
          ),
        ],
      ),
    );
  }
}

  
void restartApp(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => MapSample()),  // Replace with your root widget
    (route) => false,
  );
}
