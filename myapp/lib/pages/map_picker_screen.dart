import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLocation;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  final List<dynamic> _suggestions = [];
  static const LatLng _defaultLocation =
      LatLng(37.7749, -122.4194); // Default location
  final String _apiKey =
      ''; // Replace with your API key

  void _onMapTap(LatLng location) {
    setState(() {
      _pickedLocation = location;
    });
  }

  void _onConfirm() {
    if (_pickedLocation != null) {
      Navigator.pop(context, _pickedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please pick a location first.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _goToDefaultLocation() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_defaultLocation, 12),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.isNotEmpty) {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_apiKey',
      );
      try {
        final response = await http.get(url);
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['predictions'].isNotEmpty) {
          setState(() {
            _suggestions.clear();
            _suggestions.addAll(data['predictions']);
          });
        } else {
          setState(() {
            _suggestions.clear();
          });
        }
      } catch (e) {
        print(e); // Print the error for debugging
        setState(() {
          _suggestions.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching for location.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _selectPlace(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey',
    );
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        final newLocation = LatLng(location['lat'], location['lng']);

        final GoogleMapController controller = await _controller.future;
        setState(() {
          _pickedLocation = newLocation;
        });
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 12),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Place details not found.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print(e); // Print the error for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching place details.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 19, 20, 40),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 19, 20, 40),
        title: Center(
          // Center the title
          child: Text(
            'Pick Location',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _onConfirm,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        width: 200, // Compress the TextField width
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for a location',
                            hintStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(
                              color: Colors
                                  .white), // Set the text input color to white
                          onChanged: (value) {
                            _searchLocation(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          title: Text(suggestion['description']),
                          onTap: () {
                            _selectPlace(suggestion['place_id']);
                            setState(() {
                              _suggestions.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  initialCameraPosition: CameraPosition(
                    target: _defaultLocation,
                    zoom: 12,
                  ),
                  onTap: _onMapTap,
                  markers: _pickedLocation != null
                      ? {
                          Marker(
                            markerId: MarkerId('pickedLocation'),
                            position: _pickedLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue),
                            infoWindow: InfoWindow(
                              title: 'Picked Location',
                              snippet:
                                  'Lat: ${_pickedLocation!.latitude}, Lng: ${_pickedLocation!.longitude}',
                            ),
                          ),
                        }
                      : {
                          Marker(
                            markerId: MarkerId('defaultLocation'),
                            position: _defaultLocation,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed),
                            infoWindow: InfoWindow(
                              title: 'Default Location',
                              snippet:
                                  'Lat: ${_defaultLocation.latitude}, Lng: ${_defaultLocation.longitude}',
                            ),
                          ),
                        },
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _goToDefaultLocation,
                    child: Icon(Icons.my_location),
                    tooltip: 'Go to Default Location',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
