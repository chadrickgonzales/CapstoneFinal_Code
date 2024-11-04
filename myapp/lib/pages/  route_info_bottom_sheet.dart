import 'package:flutter/material.dart';
import 'package:myapp/services/routeservice.dart';

class RouteInfoBottomSheet extends StatefulWidget {
  final String estimatedTime;
  final String distance;
  final String destination; // Add destination parameter
  final Function(RouteInfoBottomSheetState) onStateCreated;
  final VoidCallback onClose;
  final RouteService routeService; // Add onClose callback

  RouteInfoBottomSheet({
    required this.estimatedTime,
    required this.distance,
    required this.destination, // Include destination here
    required this.onStateCreated,
    required this.onClose,
     required this.routeService, // Include onClose here
  });

  @override
  RouteInfoBottomSheetState createState() => RouteInfoBottomSheetState();
}

class RouteInfoBottomSheetState extends State<RouteInfoBottomSheet> {
  late String estimatedTime;
  late String distance;

  @override
  void initState() {
    super.initState();
    estimatedTime = widget.estimatedTime;
    distance = widget.distance;

    // Notify the parent of the created state
    widget.onStateCreated(this);
  }

  void updateRouteInfo(String newEstimatedTime, String newDistance) {
    setState(() {
      estimatedTime = newEstimatedTime;
      distance = newDistance;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black, // Set a background color if needed
    body: Center(
      child: Container(
        padding: EdgeInsets.all(16.0),
        height: 250,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 22, 23, 43), // Updated color
          borderRadius: BorderRadius.circular(20),
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
                fontSize: 24, // Updated font size
                fontWeight: FontWeight.bold,
                color: Colors.white, // Updated font color to white
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: 20), // Updated spacing
            Text(
              'Estimated Time: $estimatedTime',
              style: TextStyle(
                fontSize: 12, // Updated font size
                color: Colors.white, // Updated font color to white
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              'Distance Remaining: $distance km',
              style: TextStyle(
                fontSize: 12, // Updated font size
                color: Colors.white, // Updated font color to white
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              'Destination: ${widget.destination}',
              style: TextStyle(
                fontSize: 12, // Updated font size
                color: Colors.white, // Updated font color to white
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ), // Display the destination
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                widget.routeService.cancelRoute();
                Navigator.pop(context);
                widget.onClose(); // Call the close callback when closing
              },
              child: Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 89, 110, 131), // Set the background color
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 30.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Button radius
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}