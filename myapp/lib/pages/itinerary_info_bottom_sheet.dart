import 'package:flutter/material.dart';
import 'package:myapp/pages/google_map_page.dart';
import 'package:myapp/services/routeservice.dart';

class ItineraryInfoBottomSheet extends StatefulWidget {
  final String estimatedTime;
  final String distance;
  final String destination;
  final Function(ItineraryInfoBottomSheetState) onStateCreated;
  final VoidCallback onClose;
  final RouteService routeService; // Add RouteService instance

  const ItineraryInfoBottomSheet({
    required this.estimatedTime,
    required this.distance,
    required this.destination,
    required this.onStateCreated,
    required this.onClose,
    required this.routeService, // Include routeService in constructor
  });

  @override
  ItineraryInfoBottomSheetState createState() => ItineraryInfoBottomSheetState();
}

class ItineraryInfoBottomSheetState extends State<ItineraryInfoBottomSheet> {
  late String estimatedTime;
  late String distance;
  late String destination;

  @override
  void initState() {
    super.initState();
    estimatedTime = widget.estimatedTime;
    distance = widget.distance;
    destination = widget.destination;

    // Notify the parent of the created state
    widget.onStateCreated(this);
  }

  void updateRouteInfo(String newEstimatedTime, String newDistance, String newDestination) {
    setState(() {
      estimatedTime = newEstimatedTime;
      distance = newDistance;
      destination = newDestination;
    });
  }

@override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      height: 250,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 22, 23, 43),
        borderRadius: BorderRadius.circular(20), // Make all corners circular
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Set font color to white
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Destination: $destination',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white, // Set font color to white
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Estimated Time: $estimatedTime',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white, // Set font color to white
            ),
          ),
          Text(
            'Distance Remaining: $distance km',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white, // Set font color to white
            ),
          ),
          Spacer(),
          ElevatedButton(
  onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => MapSample(), // Rebuild the app
      ),
    );
    // Cancel the route
    widget.routeService.cancelRoute();

    // Close the window and cancel route
    // Close the bottom sheet
    widget.onClose(); // Perform any additional actions when closing (optional)
  },
  child: Text(
    'Cancel Route',
    style: TextStyle(fontSize: 14), // Adjust font size to make text smaller
  ),
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0), // Reduce padding
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
),
        ],
      ),
    );
  }
}